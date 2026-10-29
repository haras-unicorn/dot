{
  self.overlays.overlays.mcp-memory-service.value = final: _prev: {
    mcp-memory-service =
      let
        python = final.python3Packages;
        version = "12.4.0";

        # NOTE: the service downloads this at runtime into
        # ~/.cache/mcp_memory/onnx_models/all-MiniLM-L6-v2 - we fetch it here
        # so it can run in a sandbox without network access
        onnxModel =
          final.runCommand "mcp-memory-service-onnx-model"
            {
              src = final.fetchurl {
                url = "https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz";
                # NOTE: the digest pinned by upstream (`_MODEL_SHA256`)
                sha256 = "913d7300ceae3b2dbc2c50d1de4baacab4be7b9380491c27fab7418616a16ec3";
              };
            }
            ''
              mkdir -p "$out"
              tar -xzf "$src" -C "$out"
              test -f "$out/onnx/model.onnx"
              test -f "$out/onnx/tokenizer.json"
            '';

        # NOTE: same story for the cross-encoder used for reranking and quality
        # scoring - the service would otherwise export it with torch at runtime
        rerankModel =
          let
            repo = "https://huggingface.co/cross-encoder/ms-marco-MiniLM-L-6-v2/resolve/main";
          in
          final.runCommand "mcp-memory-service-rerank-model"
            {
              model = final.fetchurl {
                url = "${repo}/onnx/model.onnx";
                hash = "sha256-XT5w/Qyf8UubUWmlHpV7epx0iXr9CjXOS9MYFQwdTUo=";
              };
              tokenizer = final.fetchurl {
                url = "${repo}/tokenizer.json";
                hash = "sha256-0kGmDV6PBMwbKz6e96SSGye/Um2fYFCrkPkmeh+eXGY=";
              };
            }
            ''
              mkdir -p "$out"
              cp "$model" "$out/model.onnx"
              cp "$tokenizer" "$out/tokenizer.json"
            '';
      in
      python.buildPythonApplication {
        pname = "mcp-memory-service";
        inherit version;
        pyproject = true;

        src = final.fetchPypi {
          pname = "mcp_memory_service";
          inherit version;
          hash = "sha256-QKdQqL07zdw1qoBfDiNYjAkRmjJmukNnIGCOBBQ9QxE=";
        };

        build-system = [ python.hatchling ];

        # NOTE: upstream lists python-semantic-release as a build requirement,
        # but hatchling alone builds the wheel
        pypaBuildFlags = [ "--skip-dependency-check" ];

        # NOTE: base dependencies plus the `sqlite` extra (ONNX embeddings)
        # and scikit-learn for consolidation clustering
        dependencies = with python; [
          aiofiles
          aiohttp
          aiosqlite
          apscheduler
          authlib
          build
          certifi
          chardet
          click
          cryptography
          fastapi
          httpx
          mcp
          numpy
          psutil
          pyjwt
          pypdf
          python-dotenv
          python-multipart
          pyyaml
          requests
          sqlite-vec
          sse-starlette
          uvicorn
          zeroconf

          huggingface-hub
          onnxruntime
          tokenizers

          scikit-learn
        ];

        # NOTE: upstream pins very recent lower bounds
        pythonRelaxDeps = true;

        pythonImportsCheck = [ "mcp_memory_service" ];

        doCheck = false;

        passthru = {
          inherit onnxModel rerankModel;

          # NOTE: discovery for the streamable HTTP transport
          tests.http =
            final.runCommand "mcp-memory-service-http"
              {
                nativeBuildInputs = [
                  final.harasPackages.mcp-memory-service
                  final.curl
                ];
              }
              ''
                export HOME="$TMPDIR/home"
                mkdir -p \
                  "$HOME/.cache/mcp_memory/onnx_models/all-MiniLM-L6-v2" \
                  "$TMPDIR/memory"
                ln -s ${onnxModel}/onnx \
                  "$HOME/.cache/mcp_memory/onnx_models/all-MiniLM-L6-v2/onnx"

                export MCP_MEMORY_STORAGE_BACKEND=sqlite_vec
                export MCP_MEMORY_BASE_DIR="$TMPDIR/memory"
                export MCP_MEMORY_SQLITE_PATH="$TMPDIR/memory/sqlite_vec.db"
                export MCP_MEMORY_USE_ONNX=1
                export MCP_MEMORY_ONNX_ALLOW_DOWNLOAD=0
                export MCP_MEMORY_OFFLINE=1
                export HF_HUB_OFFLINE=1
                export TRANSFORMERS_OFFLINE=1
                export MCP_API_KEY=testkey

                memory server --streamable-http --sse-host 127.0.0.1 --sse-port 8765 \
                  > "$TMPDIR/out" 2> "$TMPDIR/err" &
                pid=$!

                for _ in $(seq 1 90); do
                  curl -s -o /dev/null http://127.0.0.1:8765/ && break
                  sleep 1
                done

                init='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"0"}}}'
                for path in /mcp /mcp/ /sse /; do
                  echo "=== no key $path"
                  curl -sS -i -m 20 -X POST "http://127.0.0.1:8765$path" \
                    -H 'Content-Type: application/json' \
                    -H 'Accept: application/json, text/event-stream' \
                    -d "$init" | head -c 600 || true
                  echo
                done
                echo "=== with bearer /mcp"
                curl -sS -i -m 20 -X POST http://127.0.0.1:8765/mcp \
                  -H 'Content-Type: application/json' \
                  -H 'Accept: application/json, text/event-stream' \
                  -H 'Authorization: Bearer testkey' \
                  -d "$init" | head -c 600 || true
                echo
                echo "=== with x-api-key /mcp"
                curl -sS -i -m 20 -X POST http://127.0.0.1:8765/mcp \
                  -H 'Content-Type: application/json' \
                  -H 'Accept: application/json, text/event-stream' \
                  -H 'X-API-Key: testkey' \
                  -d "$init" | head -c 600 || true
                echo

                echo "--- server stderr"
                tail -n 40 "$TMPDIR/err"
                kill "$pid" || true
                touch "$out"
              '';

          # NOTE: starts the server offline with the pre-fetched model and
          # talks MCP to it over stdio
          tests.smoke =
            final.runCommand "mcp-memory-service-smoke"
              {
                nativeBuildInputs = [ final.harasPackages.mcp-memory-service ];
              }
              ''
                export HOME="$TMPDIR/home"
                mkdir -p \
                  "$HOME/.cache/mcp_memory/onnx_models/all-MiniLM-L6-v2" \
                  "$TMPDIR/memory"
                ln -s ${onnxModel}/onnx \
                  "$HOME/.cache/mcp_memory/onnx_models/all-MiniLM-L6-v2/onnx"
                ln -s ${rerankModel} \
                  "$HOME/.cache/mcp_memory/onnx_models/ms-marco-MiniLM-L-6-v2"

                export MCP_MEMORY_STORAGE_BACKEND=sqlite_vec
                export MCP_MEMORY_BASE_DIR="$TMPDIR/memory"
                export MCP_MEMORY_SQLITE_PATH="$TMPDIR/memory/sqlite_vec.db"
                export MCP_MEMORY_USE_ONNX=1
                export MCP_MEMORY_ONNX_ALLOW_DOWNLOAD=0
                export MCP_MEMORY_OFFLINE=1
                export MCP_RERANK_ENABLED=true
                export MCP_RERANK_MODEL=ms-marco-MiniLM-L-6-v2
                export HF_HUB_OFFLINE=1
                export TRANSFORMERS_OFFLINE=1

                {
                  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}'
                  sleep 20
                  echo '{"jsonrpc":"2.0","method":"notifications/initialized"}'
                  echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
                  echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"memory_store","arguments":{"content":"The quick brown fox jumps over the lazy dog","metadata":{"tags":"smoke"}}}}'
                  sleep 40
                  echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"memory_search","arguments":{"query":"a fast animal leaping over a sleepy pet"}}}'
                  sleep 40
                  echo '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"memory_search","arguments":{"query":"a fast animal leaping over a sleepy pet","rerank":true,"include_debug":true}}}'
                  sleep 40
                } | timeout 300 memory server > "$TMPDIR/out" 2> "$TMPDIR/err" || true

                grep '"id":2' "$TMPDIR/out" | grep -q memory_store
                echo "--- rerank search"
                grep '"id":5' "$TMPDIR/out" | cut -c1-2500
                echo "--- stderr"
                tail -n 60 "$TMPDIR/err"

                grep '"id":5' "$TMPDIR/out" | grep -q 'lazy dog'

                # NOTE: reranking fails open to the plain order, so a passing
                # search alone proves nothing
                if grep -q 'rerank degraded' "$TMPDIR/err"; then
                  echo "reranking silently degraded"
                  exit 1
                fi
                grep '"id":4' "$TMPDIR/out" | grep -q 'lazy dog' || {
                  echo "--- stdout"; cut -c1-600 "$TMPDIR/out"
                  echo "--- stderr"; tail -n 60 "$TMPDIR/err"
                  exit 1
                }
                touch "$out"
              '';
        };

        meta = {
          description = "Persistent semantic memory MCP server with consolidation";
          homepage = "https://github.com/doobidoo/mcp-memory-service";
          license = final.lib.licenses.asl20;
          mainProgram = "memory";
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        };
      };
  };
}
