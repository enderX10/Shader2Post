#define rot(x) mat2(cos(x+vec4(0,11,33,0)))

//formula for creating colors;
#define H(h)  (  cos(  h*2. +  vec3(1,2,3)   )*.5 + .3 )

//formula for mapping scale factor
#define M(c)  log(1.+c)

#define R iResolution



void mainImage( out vec4 O, vec2 U) {

    O = vec4(0);

    vec3 c=vec3(0);
    vec4 rd = normalize( vec4(U-.5*R.xy, R.y, .3*R.y))*50.;

    float sc,dotp,totdist=0., tt=iTime/3., t=0.;

    rd.yz  *= rot(.5);
    rd.xz  *= rot( iTime/7. );

    for (float i=0.; i<80.; i++) {

        vec4 p = vec4( rd*totdist);

        float shell = length(p) - 1.;

        //p.xz += iTime/3.;
        p.x += 2.;

        p.y += iTime;

        float dd = 3.5;
        p.xyz = mod(p.xyz-dd,2.*dd)-dd;


        sc = 1.;

        vec4 w = p;

        for (float j=0.; j<5.; j++) {

            p = abs(p)*.95 - .25;

            p.xw *= rot(.4);

            dotp = clamp(1./dot(p,p),.1,6.);
            sc *= dotp;

            p = p * dotp - .5;


        }

        float dist = max( -shell, (length(p.yzw)-.1*length(p.xyz) ) /  sc  ) ;
        float stepsize = dist/30. ;
        totdist += stepsize;

        if (dist < 1e-9) break;

        if (i > 14.)
        c +=
             .04 * H(M(sc))   *  exp(-totdist*20.);
    }

    c = 1. - exp(-c*c);
    O = ( vec4(c,0) ) + .95*texture(iChannel0, U/R.xy);

}