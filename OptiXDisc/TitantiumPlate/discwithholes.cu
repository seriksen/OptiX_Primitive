#include <optix.h>
#include <optixu/optixu_aabb_namespace.h>
#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

using namespace optix;

// Communication Variables
rtDeclareVariable(float4, disc_shape, , );
rtDeclareVariable(float3, disc_max, , );
rtDeclareVariable(float3, disc_min, , );
rtDeclareVariable(optix::Ray, ray, rtCurrentRay, );
rtDeclareVariable(float3, texcoord, attribute texcoord, );
rtDeclareVariable(float3, geometric_normal, attribute geometric_normal, );
rtDeclareVariable(float3, shading_normal, attribute shading_normal, );


RT_PROGRAM void intersect(int) {

  /*
   * for disc
   *                 ^ n
   *         i       |
   * --------*-------C--------------------
   *       d/        |----------r-------->|
   *       /
   *      * O
   *
   * Ray direction = d
   * Ray origin = O
   * disc centre = C
   * disc radius = r
   *
   * ray position = ray origin + time * ray direction
   * -> r(t) = O + t * d
   *
   * Ray intercepts with Disc if
   * 1. Is in plane
   * 2. Is within disc radius
   *
   * Ray intersects plane which disc is in if
   * (r(t) - C) . n = 0
   *
   * Ray is within radius if
   * | i - C | < r
   *
   * Let r(t) = i
   *
   * -> r(t) - C < r
   * -> (r(t) - C)^2 < r^2 (so handles both directions)
   *
   * In that case, t must satisfy O + td - C = 0
   *
   * t = (disc centre - ray origin) / ray direction  in normalised plane
   * -> t = (C - o) / d   . n (for normalised plane)
   *
   * So ray intercepts disc if...
   * r_sq = (r(t) - c).(r(t) - c) < disc_rr
   * = (o + td - c).(o + td - c)
   * only care about n direction and let o - c = m
   * = (m + td) . (m + td)
   * = mm + 2tdm + ttdd
   * = t (2dm + tdd) + mm
   * = t (2d (o-c) + tdd) + (o-c)(o-c)
   * r_sq < disc_rr
   *
   * For the holes
   * hole is in same plane so only need to worry about radius
   * this time
   * | i - C | > r to be outside of hole
   */

  // Disc properties
  float disc_r = disc_shape.w;
  float3 disc_c = make_float3(disc_shape.x,disc_shape.y,disc_shape.z);
  float3 disc_n = make_float3(0.f,0.f,1.f); // normal

  // ray properties
  float3 ray_d = ray.direction;
  float3 ray_o = ray.origin;

  // t
  float disc_t = dot((disc_c - ray_o), disc_n) / dot (ray_d,disc_n);
  float t_min = 0.f;
  float t;

  // check if intersects
  float disc_r_sq = disc_t * (2.f * dot((ray_o-disc_c), ray_d) + disc_t * dot(ray_d,ray_d))
               + dot(ray_o-disc_c,ray_o-disc_c);
  float disc_rr = disc_r*disc_r;

  if (disc_r_sq < disc_rr && disc_t > t_min) {
      // Now check holes
      float3 hole_c;
      float hole_r{7.6 + 0.2}; // cm
      float hole_t;
      float hole_r_sq;
      float hole_rr;
      //float height{0.635}; // cm
      float correction_factor{disc_r / 77.9};
      hole_r = hole_r * correction_factor;
      float TopPMTArrayXY[253][2] = { { 0, 0 },
                                     { 92, 0 },
                                     { 46, 79.674337 },
                                     { -46, 79.674337 },
                                     { -92, 0 },
                                     { -46, -79.674337 },
                                     { 46, -79.674337 },
                                     { 138, 79.674337 },
                                     { 0, 159.348674 },
                                     { -138, 79.674337 },
                                     { -138, -79.674337 },
                                     { 0, -159.348674 },
                                     { 138, -79.674337 },
                                     { 184, 0 },
                                     { 92, 159.348674 },
                                     { -92, 159.348674 },
                                     { -184, 0 },
                                     { -92, -159.348674 },
                                     { 92, -159.348674 },
                                     { 230, 79.674337 },
                                     { 184, 159.348674 },
                                     { 46, 239.023011 },
                                     { -46, 239.023011 },
                                     { -184, 159.348674 },
                                     { -230, 79.674337 },
                                     { -230, -79.674337 },
                                     { -184, -159.348674 },
                                     { -46, -239.023011 },
                                     { 46, -239.023011 },
                                     { 184, -159.348674 },
                                     { 230, -79.674337 },
                                     { 276, 0 },
                                     { 138, 239.023011 },
                                     { -138, 239.023011 },
                                     { -276, 0 },
                                     { -138, -239.023011 },
                                     { 138, -239.023011 },
                                     { 276, 159.348674 },
                                     { 0, 318.697349 },
                                     { -276, 159.348674 },
                                     { -276, -159.348674 },
                                     { 0, -318.697349 },
                                     { 276, -159.348674 },
                                     { 322, 79.674337 },
                                     { 230, 239.023011 },
                                     { 92, 318.697349 },
                                     { -92, 318.697349 },
                                     { -230, 239.023011 },
                                     { -322, 79.674337 },
                                     { -322, -79.674337 },
                                     { -230, -239.023011 },
                                     { -92, -318.697349 },
                                     { 92, -318.697349 },
                                     { 230, -239.023011 },
                                     { 322, -79.674337 },
                                     { 368, 0 },
                                     { 184, 318.697349 },
                                     { -184, 318.697349 },
                                     { -368, 0 },
                                     { -184, -318.697349 },
                                     { 184, -318.697349 },
                                     { 366.828253, 158.856641 },
                                     { 320.988013, 238.254266 },
                                     { 45.84024, 397.110906 },
                                     { -45.84024, 397.110906 },
                                     { -320.988013, 238.254266 },
                                     { -366.828253, 158.856641 },
                                     { -366.828253, -158.856641 },
                                     { -320.988013, -238.254266 },
                                     { -45.84024, -397.110906 },
                                     { 45.84024, -397.110906 },
                                     { 320.988013, -238.254266 },
                                     { 366.828253, -158.856641 },
                                     { 408.490432, 76.572819 },
                                     { 270.559222, 315.476682 },
                                     { 137.931209, 392.0495 },
                                     { -137.931209, 392.0495 },
                                     { -270.559222, 315.476682 },
                                     { -408.490432, 76.572819 },
                                     { -408.490432, -76.572819 },
                                     { -270.559222, -315.476682 },
                                     { -137.931209, -392.0495 },
                                     { 137.931209, -392.0495 },
                                     { 270.559222, -315.476682 },
                                     { 408.490432, -76.572819 },
                                     { 473.546359, -0.066348 },
                                     { 236.830639, 410.070002 },
                                     { -236.71572, 410.136351 },
                                     { -473.546359, 0.066348 },
                                     { -236.830639, -410.070002 },
                                     { 236.71572, -410.136351 },
                                     { 412.663978, 238.171147 },
                                     { 0.069725, 476.463062 },
                                     { -412.594253, 238.291915 },
                                     { -412.663978, -238.171147 },
                                     { -0.069725, -476.463062 },
                                     { 412.594253, -238.291915 },
                                     { 456.929688, 162.592795 },
                                     { 369.274335, 314.41632 },
                                     { 87.655353, 477.009115 },
                                     { -87.655353, 477.009115 },
                                     { -369.274335, 314.41632 },
                                     { -456.929688, 162.592795 },
                                     { -456.929688, -162.592795 },
                                     { -369.274335, -314.41632 },
                                     { -87.655353, -477.009115 },
                                     { 87.655353, -477.009115 },
                                     { 369.274335, -314.41632 },
                                     { 456.929688, -162.592795 },
                                     { 494.720323, 84.619819 },
                                     { 320.643074, 386.130458 },
                                     { 174.077248, 470.750277 },
                                     { -174.077248, 470.750277 },
                                     { -320.643074, 386.130458 },
                                     { -494.720323, 84.619819 },
                                     { -494.720323, -84.619819 },
                                     { -320.643074, -386.130458 },
                                     { -174.077248, -470.750277 },
                                     { 174.077248, -470.750277 },
                                     { 320.643074, -386.130458 },
                                     { 494.720323, -84.619819 },
                                     { 504.218985, 240.724937 },
                                     { 460.583403, 316.303982 },
                                     { 43.635582, 557.028918 },
                                     { -43.635582, 557.028918 },
                                     { -460.583403, 316.303982 },
                                     { -504.218985, 240.724937 },
                                     { -504.218985, -240.724937 },
                                     { -460.583403, -316.303982 },
                                     { -43.635582, -557.028918 },
                                     { 43.635582, -557.028918 },
                                     { 460.583403, -316.303982 },
                                     { 504.218985, -240.724937 },
                                     { 552.229751, 149.39181 },
                                     { 405.491978, 403.549089 },
                                     { 146.737773, 552.940898 },
                                     { -146.737773, 552.940898 },
                                     { -405.491978, 403.549089 },
                                     { -552.229751, 149.39181 },
                                     { -552.229751, -149.39181 },
                                     { -405.491978, -403.549089 },
                                     { -146.737773, -552.940898 },
                                     { 146.737773, -552.940898 },
                                     { 405.491978, -403.549089 },
                                     { 552.229751, -149.39181 },
                                     { 570.783016, 43.14026 },
                                     { 322.752069, 472.742462 },
                                     { 248.030947, 515.882722 },
                                     { -248.030947, 515.882722 },
                                     { -322.752069, 472.742462 },
                                     { -570.783016, 43.14026 },
                                     { -570.783016, -43.14026 },
                                     { -322.752069, -472.742462 },
                                     { -248.030947, -515.882722 },
                                     { 248.030947, -515.882722 },
                                     { 322.752069, -472.742462 },
                                     { 570.783016, -43.14026 },
                                     { 590.793211, 245.349599 },
                                     { 507.875591, 388.967129 },
                                     { 82.91762, 634.316729 },
                                     { -82.91762, 634.316729 },
                                     { -507.875591, 388.967129 },
                                     { -590.793211, 245.349599 },
                                     { -590.793211, -245.349599 },
                                     { -507.875591, -388.967129 },
                                     { -82.91762, -634.316729 },
                                     { 82.91762, -634.316729 },
                                     { 507.875591, -388.967129 },
                                     { 590.793211, -245.349599 },
                                     { 646.325679, 85.74534 },
                                     { 397.420482, 516.861787 },
                                     { 248.905197, 602.607127 },
                                     { -248.905197, 602.607127 },
                                     { -397.420482, 516.861787 },
                                     { -646.325679, 85.74534 },
                                     { -646.325679, -85.74534 },
                                     { -397.420482, -516.861787 },
                                     { -248.905197, -602.607127 },
                                     { 248.905197, -602.607127 },
                                     { 397.420482, -516.861787 },
                                     { 646.325679, -85.74534 },
                                     { 635.947962, 171.416892 },
                                     { 466.425365, 465.038645 },
                                     { 169.522598, 636.455537 },
                                     { -169.522598, 636.455537 },
                                     { -466.425365, 465.038645 },
                                     { -635.947962, 171.416892 },
                                     { -635.947962, -171.416892 },
                                     { -466.425365, -465.038645 },
                                     { -169.522598, -636.455537 },
                                     { 169.522598, -636.455537 },
                                     { 466.425365, -465.038645 },
                                     { 635.947962, -171.416892 },
                                     { 659.264523, -0.018865 },
                                     { 570.940173, 329.630743 },
                                     { 329.648599, 570.930392 },
                                     { 0.001489, 659.264065 },
                                     { -329.615923, 570.949257 },
                                     { -570.938683, 329.633322 },
                                     { -659.264523, 0.018865 },
                                     { -570.940173, -329.630743 },
                                     { -329.648599, -570.930392 },
                                     { -0.001489, -659.264065 },
                                     { 329.615923, -570.949257 },
                                     { 570.938683, -329.633322 },
                                     { 731.430591, 47.940493 },
                                     { 718.915611, 143.001204 },
                                     { 694.099786, 235.615124 },
                                     { 657.407722, 324.197605 },
                                     { 609.467223, 407.232986 },
                                     { 551.098576, 483.300486 },
                                     { 483.300481, 551.098581 },
                                     { 407.23298, 609.467226 },
                                     { 324.197611, 657.407719 },
                                     { 235.61513, 694.099784 },
                                     { 143.00121, 718.91561 },
                                     { 47.940499, 731.43059 },
                                     { -47.940499, 731.43059 },
                                     { -143.00121, 718.91561 },
                                     { -235.61513, 694.099784 },
                                     { -324.197611, 657.407719 },
                                     { -407.23298, 609.467226 },
                                     { -483.300481, 551.098581 },
                                     { -551.098576, 483.300486 },
                                     { -609.467223, 407.232986 },
                                     { -657.407722, 324.197605 },
                                     { -694.099786, 235.615124 },
                                     { -718.915611, 143.001204 },
                                     { -731.430591, 47.940493 },
                                     { -731.430591, -47.940493 },
                                     { -718.915611, -143.001204 },
                                     { -694.099786, -235.615124 },
                                     { -657.407722, -324.197605 },
                                     { -609.467223, -407.232986 },
                                     { -551.098576, -483.300486 },
                                     { -483.300481, -551.098581 },
                                     { -407.23298, -609.467226 },
                                     { -324.197611, -657.407719 },
                                     { -235.61513, -694.099784 },
                                     { -143.00121, -718.91561 },
                                     { -47.940499, -731.43059 },
                                     { 47.940499, -731.43059 },
                                     { 143.00121, -718.91561 },
                                     { 235.61513, -694.099784 },
                                     { 324.197611, -657.407719 },
                                     { 407.23298, -609.467226 },
                                     { 483.300481, -551.098581 },
                                     { 551.098576, -483.300486 },
                                     { 609.467223, -407.232986 },
                                     { 657.407722, -324.197605 },
                                     { 694.099786, -235.615124 },
                                     { 718.915611, -143.001204 },
                                     { 731.430591, -47.940493 } };

      for (int i = 0; i < 253; i++) {
        hole_c = make_float3(TopPMTArrayXY[i][0] * correction_factor,
                            TopPMTArrayXY[i][1] * correction_factor, 0.f);

        hole_t = dot((hole_c - ray_o), disc_n) / dot(ray_d, disc_n);
        hole_r_sq = hole_t * (2.f * dot((ray_o - hole_c), ray_d) +
                              hole_t * dot(ray_d, ray_d)) +
                    dot(ray_o - hole_c, ray_o - hole_c);
        hole_rr = hole_r * hole_r;
        if (hole_r_sq < hole_rr && hole_t < t_min) {
          return;
        }
      }
      if (rtPotentialIntersection(disc_t)) {
          shading_normal = geometric_normal = normalize(disc_n);
            rtReportIntersection(0);
          }
  }
  return;
}

RT_PROGRAM void bounds(int, float result[6]) {
  optix::Aabb *aabb = (optix::Aabb *)result;
  aabb->set(disc_min, disc_max);
}
