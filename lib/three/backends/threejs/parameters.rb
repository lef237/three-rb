# frozen_string_literal: true

module Three
  module Backends
    class ThreeJS
      module Parameters
        private

        def material_parameters(material)
          parameters = {
            opacity: material.opacity,
            transparent: material.transparent,
            visible: material.visible,
            side: material.side,
            vertexColors: material.vertex_colors
          }
          parameters[:color] = material.color.hex if material.respond_to?(:color)
          parameters[:emissive] = material.emissive.hex if material.respond_to?(:emissive)
          parameters[:specular] = material.specular.hex if material.respond_to?(:specular)
          parameters[:shininess] = material.shininess if material.respond_to?(:shininess)
          parameters[:roughness] = material.roughness if material.respond_to?(:roughness)
          parameters[:metalness] = material.metalness if material.respond_to?(:metalness)
          parameters[:anisotropy] = material.anisotropy if material.respond_to?(:anisotropy)
          parameters[:anisotropyRotation] = material.anisotropy_rotation if material.respond_to?(:anisotropy_rotation)
          parameters[:clearcoat] = material.clearcoat if material.respond_to?(:clearcoat)
          parameters[:clearcoatRoughness] = material.clearcoat_roughness if material.respond_to?(:clearcoat_roughness)
          parameters[:transmission] = material.transmission if material.respond_to?(:transmission)
          parameters[:thickness] = material.thickness if material.respond_to?(:thickness)
          parameters[:ior] = material.ior if material.respond_to?(:ior)
          parameters[:reflectivity] = material.reflectivity if material.respond_to?(:reflectivity)
          parameters[:iridescence] = material.iridescence if material.respond_to?(:iridescence)
          parameters[:iridescenceIOR] = material.iridescence_ior if material.respond_to?(:iridescence_ior)
          if material.respond_to?(:iridescence_thickness_range) && material.iridescence_thickness_range
            parameters[:iridescenceThicknessRange] = material.iridescence_thickness_range.dup
          end
          parameters[:sheen] = material.sheen if material.respond_to?(:sheen)
          parameters[:sheenColor] = material.sheen_color.hex if material.respond_to?(:sheen_color)
          parameters[:sheenRoughness] = material.sheen_roughness if material.respond_to?(:sheen_roughness)
          parameters[:dispersion] = material.dispersion if material.respond_to?(:dispersion)
          parameters[:specularIntensity] = material.specular_intensity if material.respond_to?(:specular_intensity)
          parameters[:specularColor] = material.specular_color.hex if material.respond_to?(:specular_color)
          parameters[:attenuationDistance] = material.attenuation_distance if material.respond_to?(:attenuation_distance) && material.attenuation_distance
          parameters[:attenuationColor] = material.attenuation_color.hex if material.respond_to?(:attenuation_color)
          parameters[:linewidth] = material.linewidth if material.respond_to?(:linewidth)
          parameters[:linecap] = material.linecap if material.respond_to?(:linecap)
          parameters[:linejoin] = material.linejoin if material.respond_to?(:linejoin)
          parameters[:size] = material.size if material.respond_to?(:size)
          parameters[:sizeAttenuation] = material.size_attenuation if material.respond_to?(:size_attenuation)
          parameters[:fog] = material.fog if material.respond_to?(:fog)
          material_texture_parameters(material).each do |ruby_name, threejs_name|
            texture = material.public_send(ruby_name)
            parameters[threejs_name] = texture ? sync(texture) : nil
          end
          parameters[:wireframe] = material.wireframe if material.respond_to?(:wireframe)
          parameters[:flatShading] = material.flat_shading if material.respond_to?(:flat_shading)
          parameters
        end

        def material_texture_parameters(material)
          MATERIAL_TEXTURE_PARAMETERS.select { |ruby_name, _threejs_name| material.respond_to?(ruby_name) }
        end

        def light_shadow_parameters(light)
          parameters = {
            map_size: light.shadow_map_size,
            bias: light.shadow_bias,
            normal_bias: light.shadow_normal_bias,
            radius: light.shadow_radius
          }
          parameters[:camera] = light.shadow_camera if light.respond_to?(:shadow_camera)
          parameters
        end

        def texture_parameters(texture)
          {
            flip_y: texture.flip_y,
            wrap_s: texture.wrap_s,
            wrap_t: texture.wrap_t,
            mag_filter: texture.mag_filter,
            min_filter: texture.min_filter,
            offset: texture.offset.to_a,
            repeat: texture.repeat.to_a,
            center: texture.center.to_a,
            rotation: texture.rotation,
            matrix_auto_update: texture.matrix_auto_update,
            matrix: texture.matrix.to_a
          }
        end
      end

      include Parameters
    end
  end
end
