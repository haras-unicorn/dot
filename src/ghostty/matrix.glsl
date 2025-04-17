// Matrix rain effect for Ghostty (Shadertoy API format)
#version 420

uniform vec3 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// Matrix parameters
const float DENSITY = 1.0;              // How many rain streams
const float SPEED = 1.0;                // Rain speed
const vec3 COLOR = vec3(0.0, 0.8, 0.2); // Matrix green

float random(vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // Get terminal content
  vec2 uv = fragCoord / iResolution.xy;
  vec4 terminal = texture(iChannel0, uv);
  
  // Create matrix rain effect
  float cols = iResolution.x / 10.0 * DENSITY;
  float x = floor(uv.x * cols) / cols;
  
  // Different streams have different speeds
  float speed = SPEED * (0.5 + random(vec2(x)));
  float y = fract(uv.y + iTime * speed);
  
  // Fade as it goes down
  float intensity = (1.0 - y) * 0.8;
  
  // Random brightness for each character
  float brightness = random(vec2(x, floor(y * 30.0) / 30.0));
  brightness = pow(brightness, 5.0) * 2.0;
  
  // Matrix effect
  vec3 matrixEffect = COLOR * brightness * intensity;
  
  // Blend with terminal
  fragColor = terminal + vec4(matrixEffect, 0.0);
}
