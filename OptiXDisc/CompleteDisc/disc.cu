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

  float radius = disc_shape.w;
  float3 center = make_float3(disc_shape.x,disc_shape.y,disc_shape.z);

  float3 m = ray.origin - center;
  float3 n = ray.direction;
  float3 d = make_float3(0.f,0.f,1.f); // normal
  float rr = radius*radius;

  float mm = dot(m, m) ;
  float nn = dot(n, n) ;
  float nd = dot(n, d) ;   // >0 : ray direction in same hemi as normal
  float md = dot(m, d) ;
  float mn = dot(m, n) ;

  float t_min = 0.f;

  float t_center = -md/nd ;
  float rsq = t_center*(2.f*mn + t_center*nn) + mm;

  float t_cand = ( rsq < rr) ? t_center : t_min ;

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