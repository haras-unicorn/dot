const vec3 GLOW_COLOR = vec3(0.7, 0.3, 0.9);  // Pretty purple!
const float FADE_SPEED = 2.0;  // How fast the glow fades
const float GLOW_RADIUS = 0.15;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / iResolution.xy;
  
  // Get current and previous frame
  vec4 current = texture(iChannel0, uv);
  vec4 previous = texture(iChannel1, uv);
  
  // Check if pixel changed (meaning we typed something!)
  bool changed = length(current - previous) > 0.1;
  
  // Get time since last change
  float lastChange = texture(iChannel2, uv).r;
  float timeSinceChange = changed ? 0.0 : lastChange + iTime;
  
  // Calculate glow based on how recently pixels changed
  float glow = exp(-timeSinceChange * FADE_SPEED);
  
  // Add some bloom around the glowing pixels
  float bloom = 0.0;
  for(float x = -GLOW_RADIUS; x <= GLOW_RADIUS; x += 0.03) {
    for(float y = -GLOW_RADIUS; y <= GLOW_RADIUS; y += 0.03) {
      vec2 offset = uv + vec2(x, y);
      float nearby = texture(iChannel2, offset).r;
      bloom += exp(-nearby * FADE_SPEED);
    }
  }
  
  // Mix it all together!
  vec3 glowEffect = GLOW_COLOR * (glow + bloom * 0.1);
  fragColor = current + vec4(glowEffect, 0.0);
}
