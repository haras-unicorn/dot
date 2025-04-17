// Typing glow effect for Ghostty (Shadertoy API format)
#version 420

uniform vec3 iResolution;      // Viewport resolution (pixels)
uniform float iTime;           // Shader playback time (seconds)
uniform vec4 iMouse;           // Mouse position
uniform sampler2D iChannel0;   // Input texture (terminal screen)

// Glow parameters
const float GLOW_RADIUS = 0.15;              // Size of the glow
const float GLOW_INTENSITY = 0.8;            // Brightness of the glow
const vec3 GLOW_COLOR = vec3(0.7, 0.3, 0.9); // Purple glow color

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // Normalize coordinates
  vec2 uv = fragCoord / iResolution.xy;
  
  // Sample the original terminal content
  vec4 originalColor = texture(iChannel0, uv);
  
  // Find bright pixels (text) in the original image
  float brightness = (originalColor.r + originalColor.g + originalColor.b) / 3.0;
  float isText = step(0.5, brightness);
  
  // Create a glow effect around text
  float glow = 0.0;
  for (float x = -GLOW_RADIUS; x <= GLOW_RADIUS; x += 0.03) {
    for (float y = -GLOW_RADIUS; y <= GLOW_RADIUS; y += 0.03) {
      vec2 samplePos = uv + vec2(x, y) * (1.0 / iResolution.xy);
      vec4 sampleColor = texture(iChannel0, samplePos);
      float sampleBrightness = (sampleColor.r + sampleColor.g + sampleColor.b) / 3.0;
      
      // Add to glow based on distance
      float dist = length(vec2(x, y)) / GLOW_RADIUS;
      glow += step(0.5, sampleBrightness) * (1.0 - dist) * 0.1;
    }
  }
  
  // Apply the glow
  vec3 glowEffect = GLOW_COLOR * glow * GLOW_INTENSITY;
  
  // Mix original color with glow
  fragColor = originalColor + vec4(glowEffect, 0.0);
}
