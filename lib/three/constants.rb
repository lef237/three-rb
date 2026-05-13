# frozen_string_literal: true

module Three
  FrontSide = 0
  BackSide = 1
  DoubleSide = 2

  NoBlending = 0
  NormalBlending = 1

  RepeatWrapping = 1000
  ClampToEdgeWrapping = 1001
  MirroredRepeatWrapping = 1002

  NearestFilter = 1003
  NearestMipmapNearestFilter = 1004
  NearestMipMapNearestFilter = 1004
  NearestMipmapLinearFilter = 1005
  NearestMipMapLinearFilter = 1005
  LinearFilter = 1006
  LinearMipmapNearestFilter = 1007
  LinearMipMapNearestFilter = 1007
  LinearMipmapLinearFilter = 1008
  LinearMipMapLinearFilter = 1008

  UVMapping = 300
  CubeReflectionMapping = 301
  CubeRefractionMapping = 302
  EquirectangularReflectionMapping = 303
  EquirectangularRefractionMapping = 304

  NoColorSpace = ""
  SRGBColorSpace = "srgb"
  LinearSRGBColorSpace = "srgb-linear"

  BasicShadowMap = 0
  PCFShadowMap = 1
  PCFSoftShadowMap = 2
  VSMShadowMap = 3
end
