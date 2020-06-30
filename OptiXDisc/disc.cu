#include <optix.h>
#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>
#include <optixu/optixu_aabb_namespace.h>

using namespace optix; // Not actually used anywhere here?

// OptiX Communication Variables
rtDeclareVariable(float4, disc_center, , );
rtDeclareVaribale(float3, disc_props, , );
rtDeclareVariable(optix::Ray, ray, rtCurrentRay, );
rtDeclareVariable(float3, texcoord, attribute texcoord, );
rtDeclareVariable(float3, geometric_normal, attribute geometric_normal, );
rtDeclareVariable(float3, shading_normal, attribute shading_normal, );


RT_PROGRAM void intersect(int)
{
  // Declare local variables
  float radius = disc_center.w;
  float3 center = make_float3(disc_center.x, disc_center.y, disc_center.z);
  float z1 = disc_prop.x;
  float z2 = disc_prop.y;
  float zc = (z1 + z2)/2.f;
  float dz = (z1 - z2)/2.f;
  float3 m = ray.origin - center;
  float3 n = ray.direction;
  float3 d = make_float3(0.f, 0.f, 1.0f);
  float mm = dot(m,m);
  float nn = dot(n,n);
  float nd = dot(n,d);
  float md = dot(m,d);
  float mn = dot(m,n);
  float rr = radius * radius;
  float ii = 0.000001f;

  float t_c = -md/nd;
  float rsq = t_c * (2.f * mn + t_c * nn) + mm;
  float dt = nd < 0.f ? -dz/nd : dz/nd;

  float root1 = t_c - dt;
  float root2 = t_c + dt;
  float t_cand = ( rsq < rr && rsq > ii ) ? ( root1 > 0.f ? root1 : root2 ) : 0.f ;

  if (t_cand > 0.f) {
    if(rtPotentialIntersection(t_cand)) {
      shading_normal = geometric_normal = normalize(d);
      rtReportIntersection(0);
    }
  }
}

RT_PROGRAM void bounds (int, float result[6])
{
  float3 disc_p = disc_props;
  float4 disc_c = disc_center;

  float3 bbmin = make_float3(disc_c.x - disc_c.w,
                             disc_c.y - disc_c.w,
                             disc_p.x);
  float3 bbmax = make_float3(disc_c.x + disc_c.w,
                             disc_c.y + disc_c.w,
                             disc_p.y);


  optix::Aabb* aabb = (optix::Aabb*)result;
  aabb->set(bbmin, bbmax);
}
