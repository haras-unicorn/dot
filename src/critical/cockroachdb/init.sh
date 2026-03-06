# Determine if this is the init node
echo "Is init node: $IS_INIT_NODE"
if [ "$IS_INIT_NODE" = "true" ]; then
  echo "Running as init node"
else
  echo "Running as non-init node, will wait for init to complete"
fi

if [ "$IS_INIT_NODE" = "true" ]; then
  # Step 1: Initialize cluster
  echo "Attempting to initialize CockroachDB cluster..."
  for i in $(seq 1 $MAX_RETRIES); do
    output=$(timeout ${INIT_TIMEOUT}s \
      runuser -u "$COCKROACHDB_USER" -- \
      cockroach init \
      --host "$INIT_HOST" \
      --certs-dir "$CERTS_DIR" \
      2>&1) && {
      echo "Cluster initialized successfully"
      break
    }

    if echo "$output" | grep -q "cluster has already been initialized"; then
      echo "Cluster already initialized, continuing..."
      break
    fi

    if [ "$i" -eq $MAX_RETRIES ]; then
      echo "Failed to initialize cluster after $MAX_RETRIES attempts"
      exit 1
    fi

    echo "Init attempt $i failed with output '$output', retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  done

  # Step 2: Create init database and table
  echo "Setting up init table..."
  for i in $(seq 1 $MAX_RETRIES); do
    if timeout ${SCRIPT_TIMEOUT}s \
      runuser -u "$COCKROACHDB_USER" -- \
      psql \
      "$DATABASE_URL" \
      --set=ON_ERROR_STOP=1 \
      -c "
        CREATE DATABASE IF NOT EXISTS init;
        USE init;
        CREATE TABLE IF NOT EXISTS init (
          hash STRING PRIMARY KEY,
          timestamp TIMESTAMP DEFAULT now()
        );
      " 2>/dev/null; then
      echo "Init table ready"
      break
    fi

    if [ "$i" -eq $MAX_RETRIES ]; then
      echo "Failed to create init table after $MAX_RETRIES attempts"
      exit 1
    fi

    echo "Init table setup attempt $i failed, retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  done

  # Init node: check if already initialized
  echo "Checking if initialization already completed..."
  existing=""
  for i in $(seq 1 $MAX_RETRIES); do
    exit_code=0
    existing=$(timeout ${SCRIPT_TIMEOUT}s \
      runuser -u "$COCKROACHDB_USER" -- \
      psql \
      "$INIT_URL" -t \
      -c "SELECT hash FROM init WHERE hash = '$INIT_HASH'" 2>/dev/null \
       | tr -d '[:space:]') || exit_code=$?

    if [ $exit_code == 0 ] || [ "$i" -eq $MAX_RETRIES ]; then
      break
    fi

    echo "Hash check attempt $i failed, retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  done

  if [ "$existing" = "$INIT_HASH" ]; then
    echo "Initialization already recorded for this hash, skipping..."
  else
    echo "Initialization not yet recorded, proceeding with SQL scripts..."

    # Step 3: Run SQL scripts (init node only)
    IFS=',' read -ra scripts <<< "$SQL_SCRIPTS"
    for script in "${scripts[@]}"; do
      [ -z "$script" ] && continue
      echo "Running SQL script: $script"
      for i in $(seq 1 $MAX_RETRIES); do
        if timeout ${SCRIPT_TIMEOUT}s \
          runuser -u "$COCKROACHDB_USER" -- \
          psql \
          "$DATABASE_URL" \
          --file "$script" \
          --set=ON_ERROR_STOP=1; then
          echo "SQL script $script completed successfully"
          break
        fi

        if [ "$i" -eq $MAX_RETRIES ]; then
          echo "SQL script $script failed after $MAX_RETRIES attempts"
          exit 1
        fi

        echo "SQL script $script attempt $i failed, retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
      done
    done

    # Step 4: Run bash scripts (init node only, after SQL scripts but before recording)
    if [ -n "$BASH_SCRIPTS" ]; then
      echo "Running bash scripts..."
      IFS=',' read -ra bash_scripts <<< "$BASH_SCRIPTS"
      for script in "${bash_scripts[@]}"; do
        [ -z "$script" ] && continue
        echo "Running bash script: $script"
        for i in $(seq 1 $MAX_RETRIES); do
          if timeout \
            ${SCRIPT_TIMEOUT}s \
            bash "$script"; then
            echo "Bash script $script completed successfully"
            break
          fi

          if [ "$i" -eq $MAX_RETRIES ]; then
            echo "Bash script $script failed after $MAX_RETRIES attempts"
            exit 1
          fi

          echo "Bash script $script attempt $i failed, retrying in $RETRY_DELAY seconds..."
          sleep $RETRY_DELAY
        done
      done
      echo "All bash scripts completed"
    fi

    # Step 5: Record successful initialization only after all scripts complete
    echo "Recording successful initialization..."
    for i in $(seq 1 $MAX_RETRIES); do
      if timeout ${SCRIPT_TIMEOUT}s \
        runuser -u "$COCKROACHDB_USER" -- \
        psql \
        "$INIT_URL" \
        --set=ON_ERROR_STOP=1 \
        -c "
          INSERT INTO init (hash)
          VALUES ('$INIT_HASH')
          ON CONFLICT (hash) DO NOTHING;
        " 2>/dev/null; then
        echo "Initialization recorded successfully"
        break
      fi

      if [ "$i" -eq $MAX_RETRIES ]; then
        echo "Failed to record initialization after $MAX_RETRIES attempts"
        exit 1
      fi

      echo "Record attempt $i failed, retrying in $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    done

    echo "CockroachDB initialization complete on init node with latest hash '$INIT_HASH'"
  fi
else
  # Non-init node: wait for init to complete
  echo "Waiting for init node to complete (hash: '$INIT_HASH')..."
  waited=0
  while [ $waited -lt $WAIT_TIMEOUT ]; do
    exit_code=0
    existing=$(timeout ${SCRIPT_TIMEOUT}s \
      runuser -u "$COCKROACHDB_USER" -- \
      psql \
      "$INIT_URL" -t \
      -c "SELECT hash FROM init WHERE hash = '$INIT_HASH'" \
      2>/dev/null \
      | tr -d '[:space:]') || exit_code=$?

    if [ $exit_code == 0 ] && [ "$existing" = "$INIT_HASH" ]; then
      echo "Init node completed successfully"
      break
    fi

    echo "Init not yet complete (last hash is '$existing'), waiting... ($waited/$WAIT_TIMEOUT seconds)"
    sleep $RETRY_DELAY
    waited=$((waited + RETRY_DELAY))
  done

  if [ $waited -ge $WAIT_TIMEOUT ]; then
    echo "Timeout waiting for init node to complete"
    exit 1
  fi

  echo "Non-init node ready"
fi
