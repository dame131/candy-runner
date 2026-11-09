"""Eevee preview render of the Dijah Dash track segment with Blender models.
Imports the exported .glb files, arranges a game-like scene (camera behind
Dijah, looking down the track), renders 720x1280 to /tmp/blender_preview.png.
Run: blender --background --python render_preview.py
"""
import bpy
import math
import os
from mathutils import Vector

MODELS = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                       "..", "godot-project", "models"))
OUT = "/tmp/blender_preview.png"


def import_glb(name, loc, rot=(0, 0, 0), scale=1.0):
    bpy.ops.import_scene.gltf(filepath=os.path.join(MODELS, name + ".glb"))
    imported = list(bpy.context.selected_objects)
    # GLBs have several top-level objects; group them under one anchor
    # so the whole model moves/rotates/scales together.
    anchor = bpy.data.objects.new(name + "_anchor", None)
    bpy.context.collection.objects.link(anchor)
    anchor.location = loc
    anchor.rotation_euler = rot
    anchor.scale = (scale, scale, scale)
    bpy.context.view_layer.update()
    for o in imported:
        if o.parent is None:
            # Leave matrix_parent_inverse as identity so the anchor's
            # transform carries the model with it (setting the inverse
            # would pin the model at its original world spot).
            o.parent = anchor
    bpy.ops.object.select_all(action="DESELECT")
    return anchor


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # --- world / lighting ---
    if "World" not in bpy.data.worlds:
        w = bpy.data.worlds.new("World")
        bpy.context.scene.world = w
    world = bpy.data.worlds["World"]
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (1.0, 0.84, 0.91, 1.0)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0

    # sun
    bpy.ops.object.light_add(type="SUN", location=(5, -5, 10))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))

    # syrup sea: big glossy pink plane
    bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 20, -0.9))
    sea = bpy.context.active_object
    m = bpy.data.materials.new("Sea")
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (1.0, 0.18, 0.49, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.08
    sea.data.materials.append(m)

    # --- track: 3 wide x 5 rows, alternating tile A/B ---
    for lane, x in enumerate((-2.2, 0.0, 2.2)):
        for row in range(5):
            y = row * 2.4
            if lane == 0 and row == 2:
                import_glb("hole_tile", (x, y, 0))
            else:
                import_glb("tile_a" if (lane + row) % 2 == 0 else "tile_b", (x, y, 0))

    # rails
    import_glb("rail_left", (-3.55, 6, 0))
    import_glb("rail_right", (3.55, 6, 0))

    # star over the hole
    import_glb("star", (0, 4.8, 0.9))

    # Dijah at the near end, facing +Y (away from camera)
    import_glb("dijah", (0, 0.5, 0))

    # props on the sides
    import_glb("lollipop", (-6.5, 3, -0.9), scale=1.4)
    import_glb("donut", (7.5, 6, -0.9), rot=(0.6, 0.3, 0.4), scale=1.3)
    import_glb("ice_cream_cone", (-7.5, 8, -0.9), scale=1.5)
    import_glb("cupcake", (6.5, 11, -0.9), scale=1.4)
    import_glb("gummy_bear", (4.6, 7, 0), scale=1.0)
    import_glb("candy_cane_arch", (0, 12, 0))
    import_glb("candy_mountain", (-16, 14, -0.9), scale=1.6)
    import_glb("candy_mountain", (18, 18, -0.9), scale=1.8)

    # --- camera: behind Dijah, slightly above, looking down the track ---
    bpy.ops.object.camera_add(location=(0, -6.5, 3.1))
    cam = bpy.context.active_object
    cam.data.lens = 40
    direction = Vector((0, 8, 0.4)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam

    # --- render ---
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 1280
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("PREVIEW RENDERED ->", OUT)


if __name__ == "__main__":
    main()
