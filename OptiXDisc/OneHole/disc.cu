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
   * = (m + tn) . (m + tn)
   * = mm + 2tnm + ttnn
   * = t (2nm + tnn) + mm
   * = t (2n (o-c) + tnn) + (o-c)(o-c)
   * r_sq < disc_rr
   *
   * For the hole
   * hole is in same plane so only need to worry about radius
   * this time
   * | i - C | > r to be outside of hole
   */

  // Disc properties
  float disc_r = disc_shape.w;
  float3 disc_c = make_float3(disc_shape.x,disc_shape.y,disc_shape.z);
  float3 disc_n = make_float3(0.f,0.f,1.f); // normal

  // Hole properties
  float3 hole_c = make_float3(disc_hole.x, disc_hole.y, disc_hole.z);
  float hole_r = disc_hole.w;

  // ray properties
  float3 ray_d = ray.direction;
  float3 ray_o = ray.origin;

  // t
  float disc_t = dot((disc_c - ray_o), disc_n) / dot (ray_d,disc_n);
  float t_min = 0.f;

  // check if intersects
  float disc_r_sq = disc_t * (2.f * dot((ray_o-disc_c), ray_d) + disc_t * dot(ray_d,ray_d))
               + dot(ray_o-disc_c,ray_o-disc_c);
  float disc_rr = disc_r*disc_r;

  if (disc_r_sq < disc_rr && disc_t > t_min) {
    // Now check hole
    float hole_t = dot((hole_c - ray_o), disc_n) / dot(ray_d,disc_n);
    float hole_r_sq = hole_t * ( dot((ray_o - hole_c), ray_d) + hole_t * dot(ray_d,ray_d))
                              + dot(ray_o - hole_c,ray_o - hole_c);
    float hole_rr = hole_r*hole_r;
    if (hole_r_sq > hole_rr && hole_t > t_min) {
      if (rtPotentialIntersection(hole_t)) {
        shading_normal = geometric_normal = normalize(disc_n);
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
