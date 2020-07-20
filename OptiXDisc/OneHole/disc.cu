#include <optix.h>
#include <optixu/optixu_aabb_namespace.h>
#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

using namespace optix;

// Communication Variables
rtDeclareVariable(float4, disc_shape, , );
rtDeclareVariable(float3, disc_max, , );
rtDeclareVariable(float3, disc_min, , );
rtDeclareVariable(float4, disc_hole, , );
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

  // Hole properties
  float3 hole_c = make_float3(disc_hole.x, disc_hole.y, disc_hole.z);
  float hole_r = disc_hole.w;

  // ray properties
  float3 d = ray.direction;
  float3 o = ray.origin;

  // t
  float t = - dot((o - c), n) / dot(d, n);
  float t_min = 0.f;

  // check if intersects
  float rt_sqrt = t * (2.f * dot((o-c), d) + t * dot(d,d)) + dot(o-c,o-c);
  float rr = r*r;

  if (rt_sqrt < rr && t > t_min) {
    // Now check hole
    float t_hole = - dot((o - hole_c), n) / dot(d, n);
    float rt_sqrt_h = t_hole * (2.f * dot((o - hole_c), d) + t * dot(d,d) + dot(o-hole_c,o-hole_c));
    float hole_rr = hole_r*hole_r;
    if (rt_sqrt > hole_rr && t_hole > t_min) {
      if (rtPotentialIntersection(t)) {
        shading_normal = geometric_normal = normalize(n);
        rtReportIntersection(0);
      }
    }
  }
  return;
}

RT_PROGRAM void bounds(int, float result[6]) {
  optix::Aabb *aabb = (optix::Aabb *)result;
  aabb->set(disc_min, disc_max);
}
