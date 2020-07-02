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
   * Ray intersects plane which disc is in if
   * (r(t) - C) . n = 0
   *
   * Ray hits disc is in plane and within radius
   * r(t) - C < r
   * -> (r(t) - C)^2 < r^2 (so handles both directions)
   *
   * t = (ray origin - disc centre) / ray direction  in normalised plane
   * -> t = (O - C).n / d.n
   */

  // Disc properties
  float r = disc_shape.w;
  float3 c = make_float3(disc_shape.x,disc_shape.y,disc_shape.z);
  float3 n = make_float3(0.f,0.f,1.f); // normal

  // ray properties
  float3 d = ray.direction;
  float3 o = ray.origin;
  float rr = radius*radius;

  // t
  float t = dot((o - c), n) / dot(d, n);

  // check if intersects
  float rt_sqrt = dot((o + t * d - c), n)*dot((o + t * d - c), n);
  float rr = r*r;

  if ( rtPotentialIntersection(t) ) {
    shading_normal = geometric_normal = normalize(n);
    rtReportIntersection(0);
  }
  return;
}

RT_PROGRAM void bounds(int, float result[6]) {
  optix::Aabb *aabb = (optix::Aabb *)result;
  aabb->set(disc_min, disc_max);
}
