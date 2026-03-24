// this is a 3D surface shader
shader_type spatial;

// render_mode unshaded — ignore lighting, draw flat colour; 
// blend_mix — enable transparency; 
// cull_disabled — visible from both sides (important for a floor quad viewed from above) 
render_mode unshaded, blend_mix, cull_disabled;

void fragment() {
    // UV is a Vector 2 where (0,0) is one corner and (1,1) is the opposite corner, so 0.5 is centered
    vec2 center = UV - vec2(0.5);
    float dist = length(center);
    float angle = atan(center.y, center.x);

    // TIME = auto-increments each frame, drives animation 
    // SPIN adds a spiral effect to the rings as per the following:
    float spin = angle + TIME * 2.0;

    // Add spin as a multiplier into rings:
    //float rings = sin(dist * 32.0 - spin * 8.0 - TIME * 4.8) * 0.5 + 0.5;

    float wobbly_dist = dist + sin(angle * 12.0 + TIME * 12.0) * 0.01;
    //  - angle * 6.0 — how many wobble bumps around the circle (6 = six bumps)                                                                                                                              
    //  - * 0.03 — how far out the bumps push (small value = subtle)                                                                                                                                       
    //  - TIME * 3.0 — makes the wobble itself rotate            
    //float rings = sin(wobbly_dist * 64.0 - TIME * 4.8) * 0.5 + 0.5;
    
    //sin() produces a wave that goes up and down between -1 and +1.                                                                                                                                       
    //The problem is that ALPHA can't go below 0 — negative values just mean "invisible", same as 0. So the wave looks like it has two states: something and nothing. But "nothing" here is rendering as   
    //black because the solid ALBEDO colour is still showing through.                                                                                                                                      
                                                                                                                                                                                                       
    //The fix * 0.5 + 0.5 just slides and squishes that wave:                                                                                                                                                                                                                                                                                                                                                
    //- * 0.5 squishes it from -1→1 to -0.5→0.5                                                                                                                                                            
    //- + 0.5 slides it up from -0.5→0.5 to 0→1   

    float mask = smoothstep(0.5, 0.1, dist);

    vec3 blue = vec3(0.2, 0.4, 1.0);
    vec3 white = vec3(0.8, 0.9, 1.0);
    // ALBEDO = the surface color output
    //ALBEDO = mix(blue, white, rings);
    // mix(a, b, t) blends between two values — when rings is 0 you get blue, when rings is 1 you get white, and in between you get a smooth blend.  

    float raw = sin(wobbly_dist * 48.0 - TIME * 4.8);                                                                                                                                                    
    float rings = pow(abs(raw), 4.0) * mask;
    // pow(x, 2.0) squishes the small values down faster, making the gaps wider while keeping the peaks bright. Try higher values like 3.0 or 4.0 for even bigger gaps.                                                                                                                                                                                 
    float color_t = raw * 0.5 + 0.5;
    // The color_t value does this — raw * 0.5 + 0.5 goes 0→1→0 each cycle, alternating blue and white. The alpha transparency is still there from abs(raw) * mask.                                                                                                                                                                  
    ALBEDO = mix(blue, white, color_t);
    ALPHA = rings * 0.6;    

    // ALPHA = transparency (0 = invisible, 1 = solid)
    // Third value (0.8) caps maximum transparency at 80%
    //ALPHA = rings * mask * 0.8;

}

