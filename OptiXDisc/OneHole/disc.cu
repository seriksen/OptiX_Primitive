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
  float3 o = ray.origin;
  float3 d = ray.direction;

  float rr = radius*radius;
  float hole_rr = hole_radius * hole_radius;

  float mm = dot(m, m) ;
  float nn = dot(n, n) ;
  float nd = dot(n, d) ;   // >0 : ray direction in same hemi as normal
  float md = dot(m, d) ;
  float mn = dot(m, n) ;

  // Remove tmin?
  float t_min = 0.f;

  float t_center = -md/nd ;
  float rsq = t_center*(2.f*mn + t_center*nn) + mm;

  // check hole center now
  float3 hole_m = ray.origin - hole_center;
  float hole_md = dot(hole_m, d);
  float hole_mm = dot(hole_m, hole_m);
  float hole_mn = dot(hole_m, n);
  float hole_t_center = -hole_md/nd;
  float hole_rsq = hole_t_center*(2.f*hole_mn + hole_t_center*nn) + hole_mm;

  // TODO let hole not be in center
  float t_cand = (rsq < rr && hole_rsq > hole_rr) ? t_center : t_min;


  bool valid_isect = t_cand > t_min ;
  if(valid_isect) {
    if( rtPotentialIntersection( t_cand ) ) {
      shading_normal = geometric_normal = normalize(d);
      rtReportIntersection(0);
        }
  }
  return;
}

RT_PROGRAM void bounds(int, float result[6]) {
  optix::Aabb *aabb = (optix::Aabb *)result;
  aabb->set(disc_min, disc_max);
}
