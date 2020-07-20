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
  float t = dot((c - o), n) / dot (d,n);
  float t_min = 0.f;

  // check if intersects
  // r_sq = (r(t) - c).(r(t) - c) < disc_rr
  // = (o + td - c).(o + td - c)
  // only care about n direction and let o - c = m
  // = (m + tn) . (m + tn)
  // = mm + 2tnm + ttnn
  // = t (2nm + tnn) + mm
  // = t (2n (o-c) + tnn) + (o-c)(o-c)

  float r_sq = t * (2.f * dot((o-c), d) + t * dot(d,d)) + dot(o-c,o-c);
  float rr = r*r;

  if (rt_sq < rr && t > t_min) {
    // Now check hole
    float t_hole = - dot((o - hole_c), n) / dot(d, n);
    float rt_sq_h = t_hole * (2.f * dot((o - hole_c), d) + t_hole * dot(d,d))
                              + dot(o - hole_c,o - hole_c));
    float hole_rr = hole_r*hole_r;
    if (rt_sq_h > hole_rr && t_hole > t_min) {
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
