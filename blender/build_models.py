"""Dijah Dash — Blender model builder (part 1: helpers, Dijah, tiles, rails, star).
Run: blender --background --python build_models.py
Exports .glb files into ../godot-project/models/.
Blender coords: Z up, +Y is "forward" (maps to Godot -Z, away from camera).
Godot mapping: Blender (x, y, z) -> Godot (x, z, -y).
"""
import bpy
import math
import os
import bmesh

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "godot-project", "models")
OUT_DIR = os.path.normpath(OUT_DIR)


def hex2rgb(h):
    # Blender material sockets expect LINEAR color; hex values are sRGB.
    # The old version skipped the conversion, so every dark color rendered
    # much lighter (near-black hair #1e1420 came out medium grey-purple).
    h = h.lstrip("#")

    def _lin(v):
        c = v / 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return tuple(_lin(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def clean():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for coll in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        pass


def gloss(name, hexcolor, rough=0.18, metallic=0.0, emit=None, emit_strength=0.0):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*hex2rgb(hexcolor), 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metallic
    if emit is not None:
        bsdf.inputs["Emission Color"].default_value = (*hex2rgb(emit), 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_strength
    return m


def _finish(obj, mat, smooth_angle=True):
    if mat is not None:
        obj.data.materials.append(mat)
    if smooth_angle:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.shade_smooth_by_angle()
        obj.select_set(False)
    return obj


def sphere(name, r, loc, mat, seg=20, rings=12, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, segments=seg, ring_count=rings, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(o, mat)


def rbox(name, dims, loc, mat, bevel_w=0.05, bevel_seg=2):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel_w > 0:
        mod = o.modifiers.new("bev", "BEVEL")
        mod.width = bevel_w
        mod.segments = bevel_seg
        mod.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return _finish(o, mat)


def cyl(name, r_top, r_bot, h, loc, mat, verts=20, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r_top, depth=h, vertices=verts, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    if r_top != r_bot:
        # cylinder primitive uses one radius; fake taper via scaling top verts is
        # complex — use cone primitive instead when tapered (handled by caller).
        pass
    return _finish(o, mat)


def cone(name, r_bottom, r_top, h, loc, mat, verts=24):
    bpy.ops.mesh.primitive_cone_add(radius1=r_bottom, radius2=r_top, depth=h, vertices=verts, location=loc)
    o = bpy.context.active_object
    o.name = name
    return _finish(o, mat)


def torus(name, major, minor, loc, mat, major_seg=32, minor_seg=12, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                     major_segments=major_seg, minor_segments=minor_seg,
                                     location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    return _finish(o, mat)


def capsule_z(name, r, length, loc, mat):
    """Vertical capsule (axis Z): cylinder + 2 hemispheres, joined."""
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=length, vertices=16, location=loc)
    parts.append(bpy.context.active_object)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, segments=16, ring_count=8,
                                         location=(loc[0], loc[1], loc[2] + length / 2))
    parts.append(bpy.context.active_object)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, segments=16, ring_count=8,
                                         location=(loc[0], loc[1], loc[2] - length / 2))
    parts.append(bpy.context.active_object)
    for p in parts:
        p.data.materials.append(mat)
        for poly in p.data.polygons:
            poly.use_smooth = True
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    j = bpy.context.active_object
    j.name = name
    return j


def tube_between(name, p1, p2, r, mat, verts=12):
    """Cylinder between two Vector-like points."""
    from mathutils import Vector
    a = Vector(p1)
    b = Vector(p2)
    mid = (a + b) / 2
    d = b - a
    length = d.length
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=length, vertices=verts, location=mid)
    o = bpy.context.active_object
    o.name = name
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    return _finish(o, mat)


def empty(name, loc):
    e = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(e)
    e.location = loc
    return e


def parent_to(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def tri_count(objs):
    total = 0
    for o in objs:
        if o.type == "MESH":
            me = o.data
            me.calc_loop_triangles()
            total += len(me.loop_triangles)
    return total


def export_glb(objs, filename):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    path = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True)
    print("EXPORTED %s (%d tris, %d bytes)" % (filename, tri_count(objs), os.path.getsize(path)))


# ---------------------------------------------------------------- Dijah ---
def build_dijah():
    clean()
    skin = gloss("Skin", "#8a5a34", 0.30)
    hair = gloss("Hair", "#1e1420", 0.6)
    top = gloss("Top", "#0e9b8a", 0.22)
    bottom = gloss("Bottom", "#ff5c8a", 0.22)
    shoes = gloss("Shoes", "#ffffff", 0.25)
    bead_y = gloss("BeadYellow", "#ffd23f", 0.2)
    bead_p = gloss("BeadPink", "#ff5c8a", 0.2)
    blush = gloss("Blush", "#ff9ec7", 0.3)
    dark = gloss("EyeDark", "#1a1a1a", 0.2)
    tattoo = gloss("Tattoo", "#b967ff", 0.3)

    root = empty("Dijah", (0, 0, 0))
    objs = [root]

    # legs (pivots at hips)
    for side, x in (("L", -0.14), ("R", 0.14)):
        piv = empty("Leg" + side, (x, 0, 0.42))
        parent_to(piv, root)
        leg = capsule_z("Leg" + side + "Mesh", 0.09, 0.30, (x, 0, 0.22), skin)
        parent_to(leg, piv)
        shoe = rbox("Shoe" + side, (0.20, 0.34, 0.12), (x, 0.05, 0.03), shoes, bevel_w=0.04)
        parent_to(shoe, piv)
        objs += [piv, leg, shoe]

    # body (teal top) — capsule, center z 0.85
    body = capsule_z("Body", 0.30, 0.25, (0, 0, 0.85), top)
    parent_to(body, root)
    # pink skirt — flared cone
    skirt = cone("Bottom", 0.38, 0.30, 0.28, (0, 0, 0.52), bottom, verts=24)
    parent_to(skirt, root)
    # butterfly tattoo on chest front (+Y in Blender = Godot -Z = her front)
    tat = rbox("Tattoo", (0.16, 0.02, 0.10), (0, 0.29, 0.98), tattoo, bevel_w=0.0)
    parent_to(tat, root)

    # arms (pivots at shoulders)
    for side, x in (("L", -0.36), ("R", 0.36)):
        piv = empty("Arm" + side, (x, 0, 1.18))
        parent_to(piv, root)
        arm = capsule_z("Arm" + side + "Mesh", 0.08, 0.34, (x, 0, 0.93), skin)
        parent_to(arm, piv)
        objs += [piv, arm]

    # head
    head = sphere("Head", 0.30, (0, 0, 1.55), skin, seg=24, rings=16)
    parent_to(head, root)
    # hair cap: back-half shell over the head so no bare skin shows
    # from behind (the camera side). Front (face) stays skin, but the
    # CROWN stays covered — the old rule (delete y > 0.02) stripped the
    # top of the head bare, which read as a skin dome from behind.
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.33, segments=24, ring_count=16,
                                         location=(0, -0.01, 1.57))
    cap = bpy.context.active_object
    cap.name = "HairCap"
    import bmesh as _bm
    _b = _bm.new()
    _b.from_mesh(cap.data)
    # Local coords: delete only front faces BELOW the crown line.
    _del = [f for f in _b.faces if f.calc_center_median().y > 0.02 and f.calc_center_median().z < 0.02]
    _bm.ops.delete(_b, geom=_del, context="FACES")
    _b.to_mesh(cap.data)
    _b.free()
    cap.data.materials.append(hair)
    bpy.context.view_layer.objects.active = cap
    cap.select_set(True)
    bpy.ops.object.shade_smooth_by_angle()
    cap.select_set(False)
    parent_to(cap, root)
    objs.append(cap)
    # eyes (front, +Y) and smile and blush
    for x in (-0.11, 0.11):
        e = sphere("Eye", 0.035, (x, 0.27, 1.58), dark, seg=10, rings=6)
        parent_to(e, root)
        objs.append(e)
    sm = rbox("Smile", (0.12, 0.02, 0.02), (0, 0.28, 1.45), dark, bevel_w=0.0)
    parent_to(sm, root)
    for x in (-0.18, 0.18):
        b = sphere("Blush", 0.06, (x, 0.24, 1.50), blush, seg=10, rings=6)
        parent_to(b, root)
        objs.append(b)
    # braids: 8 THIN hanging braids + beads, 2 buns on the crown.
    # Thin (0.05) and spaced (ring 0.28, staggered heights) so each braid
    # reads as its own strand instead of one solid curtain.
    for i in range(8):
        ang = 2 * math.pi * i / 8.0
        bx = math.cos(ang) * 0.28
        by = -math.sin(ang) * 0.28
        bz = 1.12 if i % 2 == 0 else 1.18
        br = capsule_z("Braid%d" % i, 0.05, 0.62, (bx, by, bz), hair)
        parent_to(br, root)
        bead = sphere("Bead%d" % i, 0.055, (bx, by, 0.78), bead_y if i % 2 == 0 else bead_p, seg=10, rings=6)
        parent_to(bead, root)
        objs += [br, bead]
    for x in (-0.20, 0.20):
        bun = sphere("Bun", 0.13, (x, -0.05, 1.87), hair, seg=14, rings=8)
        parent_to(bun, root)
        objs.append(bun)

    objs += [body, skirt, tat, head, sm]
    export_glb(objs, "dijah.glb")
    return objs


# ------------------------------------------------------------- track tile ---
SPRINKLE_COLORS = ["#ff5c8a", "#ffd23f", "#5fe3c0", "#b967ff", "#ffffff", "#ff8a00"]


def build_tile(variant, seed):
    """One waffle tile, 2.14 x 2.34, origin at top-center, extends down 0.35.
    Top surface at z=0 (Godot y=0 when placed at y=0)."""
    import random
    rnd = random.Random(seed)
    clean()
    tile = gloss("tile", "#e8b478", 0.18)
    pocket = gloss("waffle_pocket", "#8c5628", 0.34)
    side = gloss("side", "#3d2113", 0.35)
    # chocolate base slab
    base = rbox("Base", (2.14, 2.34, 0.35), (0, 0, -0.175), side, bevel_w=0.04)
    # recessed toasted waffle pocket bed
    top = rbox("Top", (2.06, 2.26, 0.10), (0, 0, -0.05), pocket, bevel_w=0.03)
    objs = [base, top]
    # 2x2 raised 3D waffle grid cushions with deeper relief
    for gx in (-0.47, 0.47):
        for gy in (-0.53, 0.53):
            cell = rbox("Cell", (0.84, 0.84, 0.11), (gx, gy, 0.055), tile, bevel_w=0.035)
            objs.append(cell)
    # sprinkles: tiny capsules lying flat on top (real geometry, so they
    # catch light and bloom — 12 per tile for a dense candy look)
    for i in range(12):
        sx = rnd.uniform(-0.9, 0.9)
        sy = rnd.uniform(-1.0, 1.0)
        ang = rnd.uniform(0, math.pi)
        col = SPRINKLE_COLORS[rnd.randrange(len(SPRINKLE_COLORS))]
        m = gloss("sprinkle_%s" % col.lstrip("#"), col, 0.25, emit=col, emit_strength=0.25)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.14, vertices=6,
                                            location=(sx, sy, 0.07),
                                            rotation=(math.pi / 2, 0, ang))
        sp = bpy.context.active_object
        sp.name = "Sprinkle%d" % i
        _finish(sp, m)
        objs.append(sp)
    export_glb(objs, "tile_%s.glb" % variant)
    return objs


# ------------------------------------------------------------- hole tile ----
def build_hole_tile():
    """Frame around a 2.14 x 2.34 hole, origin at top-center. Rim tubes in
    material 'rim', syrup plane 'syrup', white corner joints 'joint'."""
    clean()
    side = gloss("side", "#3d2113", 0.35)
    rim = gloss("rim", "#ff5c8a", 0.15, emit="#ff5c8a", emit_strength=0.35)
    syrup = gloss("syrup", "#7a1030", 0.08)
    joint = gloss("joint", "#ffffff", 0.25)
    objs = []
    # frame: 2 side bars + front/back bars (chocolate)
    for x in (-0.93, 0.93):
        objs.append(rbox("FrameSide", (0.28, 2.34, 0.35), (x, 0, -0.175), side, bevel_w=0.04))
    for y in (-1.03, 1.03):
        objs.append(rbox("FrameEnd", (1.58, 0.28, 0.35), (0, y, -0.175), side, bevel_w=0.04))
    # rim: 4 rounded tubes around the hole opening at top
    for (p1, p2) in [((-1.07, -1.17, 0.06), (1.07, -1.17, 0.06)),
                     ((-1.07, 1.17, 0.06), (1.07, 1.17, 0.06)),
                     ((-1.07, -1.17, 0.06), (-1.07, 1.17, 0.06)),
                     ((1.07, -1.17, 0.06), (1.07, 1.17, 0.06))]:
        objs.append(tube_between("Rim", p1, p2, 0.09, rim, verts=10))
    # white corner joints
    for cx in (-1.07, 1.07):
        for cy in (-1.17, 1.17):
            objs.append(sphere("Joint", 0.14, (cx, cy, 0.06), joint, seg=14, rings=8))
    # syrup below + bubbles
    objs.append(rbox("Syrup", (2.10, 2.30, 0.05), (0, 0, -0.85), syrup, bevel_w=0.0))
    objs.append(sphere("Bubble", 0.10, (0.4, 0.0, -0.80), joint, seg=10, rings=6))
    objs.append(sphere("Bubble2", 0.07, (-0.5, 0.3, -0.80), joint, seg=10, rings=6))
    export_glb(objs, "hole_tile.glb")
    return objs


# ------------------------------------------------------------------ rails ---
def build_rail(name, tube_hex, joint_hex):
    """12 m rail segment. Tube along Blender Y (Godot -Z), center z=0.28.
    Joints at Blender y = -5.5, -2.5, 0.5, 3.5 -> Godot z = -0.5,-3.5,-6.5,-9.5
    when instanced at segment z=-6."""
    clean()
    tube_m = gloss("rail", tube_hex, 0.15)
    joint_m = gloss("joint", joint_hex, 0.25)
    objs = []
    bpy.ops.mesh.primitive_cylinder_add(radius=0.13, depth=12.0, vertices=20,
                                        location=(0, 0, 0.28), rotation=(math.pi / 2, 0, 0))
    tube = bpy.context.active_object
    tube.name = "RailTube"
    _finish(tube, tube_m)
    objs.append(tube)
    for y in (-5.5, -2.5, 0.5, 3.5):
        objs.append(sphere("Joint", 0.20, (0, y, 0.28), joint_m, seg=16, rings=10))
    export_glb(objs, name + ".glb")
    return objs


# ------------------------------------------------------------------- star ---
def build_star():
    """5-point star standing in the XZ plane, front toward -Y (Godot +Z,
    toward the camera). Bead child of the star; ring flat on the ground
    at local y=-0.82 (star floats at 0.9 in-game, ring lands at 0.08)."""
    import bmesh
    clean()
    star_m = gloss("star", "#ffd23f", 0.15, emit="#ffd23f", emit_strength=0.4)
    bead_m = gloss("bead", "#ff5c8a", 0.2)
    ring_m = gloss("ring", "#ff5c8a", 0.25)

    outer, inner, half = 0.5, 0.21, 0.07
    me = bpy.data.meshes.new("Star")
    bm = bmesh.new()
    front, back = [], []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        r = outer if i % 2 == 0 else inner
        x = math.cos(ang) * r
        z = math.sin(ang) * r
        front.append(bm.verts.new((x, -half, z)))
        back.append(bm.verts.new((x, half, z)))
    bm.verts.ensure_lookup_table()
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    for i in range(10):
        j = (i + 1) % 10
        bm.faces.new((front[i], front[j], back[j], back[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    star = bpy.data.objects.new("Star", me)
    bpy.context.collection.objects.link(star)
    star.data.materials.append(star_m)
    mod = star.modifiers.new("bev", "BEVEL")
    mod.width = 0.03
    mod.segments = 2
    mod.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = star
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth_by_angle()
    bead = sphere("Bead", 0.12, (0, -half - 0.03, 0), bead_m, seg=14, rings=8)
    parent_to(bead, star)
    ring = torus("Ring", 0.50, 0.06, (0, 0, -0.82), ring_m, major_seg=28, minor_seg=10)
    export_glb([star, bead, ring], "star.glb")
    return [star, bead, ring]


# ------------------------------------------------------------------ props ---
def build_lollipop():
    """Swirl lollipop: white stick + pink disc + white spiral tube on face."""
    clean()
    white = gloss("LolliWhite", "#ffffff", 0.25)
    pink = gloss("LolliPink", "#f0337a", 0.15)
    objs = []
    stick = cyl("Stick", 0.09, 0.09, 2.2, (0, 0, 1.1), white, verts=12)
    objs.append(stick)
    # disc: cylinder axis along Y (face toward -Y / camera). Rotate X 90.
    bpy.ops.mesh.primitive_cylinder_add(radius=0.85, depth=0.12, vertices=28,
                                        location=(0, 0, 2.5), rotation=(math.pi / 2, 0, 0))
    disc = bpy.context.active_object
    disc.name = "Disc"
    _finish(disc, pink)
    objs.append(disc)
    # spiral: Archimedean spiral tube on the front face (y = -0.10)
    import mathutils
    pts = []
    turns = 2.2
    steps = 60
    for i in range(steps + 1):
        t = i / steps
        ang = t * turns * 2 * math.pi
        r = 0.08 + t * 0.62
        pts.append((math.cos(ang) * r, -0.10, 2.5 + math.sin(ang) * r))
    cu = bpy.data.curves.new("Spiral", "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = 0.05
    cu.bevel_resolution = 2
    spl = cu.splines.new("POLY")
    spl.points.add(len(pts) - 1)
    for p, co in zip(spl.points, pts):
        p.co = (*co, 1.0)
    spiral = bpy.data.objects.new("Spiral", cu)
    bpy.context.collection.objects.link(spiral)
    spiral.data.materials.append(white)
    # glTF export can drop raw curves — convert to mesh first.
    bpy.context.view_layer.objects.active = spiral
    spiral.select_set(True)
    bpy.ops.object.convert(target="MESH")
    spiral = bpy.context.active_object
    spiral.name = "Spiral"
    objs.append(spiral)
    export_glb(objs, "lollipop.glb")
    return objs


def build_donut():
    """Pink-frosted donut with sprinkles, tilted like the mockup."""
    clean()
    dough = gloss("Dough", "#b57a3e", 0.3)
    frost = gloss("Frosting", "#f0337a", 0.15)
    objs = []
    d = torus("Donut", 1.0, 0.5, (0, 0, 0), dough, major_seg=36, minor_seg=16)
    objs.append(d)
    # frosting: slightly bigger squashed torus on top
    f = torus("Frosting", 1.02, 0.52, (0, 0, 0.12), frost, major_seg=36, minor_seg=16)
    f.scale = (1, 1, 0.55)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    objs.append(f)
    import random
    rnd = random.Random(7)
    for i in range(14):
        ang = rnd.uniform(0, 2 * math.pi)
        rr = rnd.uniform(0.55, 1.35)
        col = rnd.choice(SPRINKLE_COLORS)
        m = gloss("sprinkle_%s" % col.lstrip("#"), col, 0.25)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.16, vertices=6,
                                            location=(math.cos(ang) * rr, math.sin(ang) * rr, 0.42),
                                            rotation=(math.pi / 2, 0, rnd.uniform(0, math.pi)))
        sp = bpy.context.active_object
        sp.name = "Sprinkle%d" % i
        _finish(sp, m)
        objs.append(sp)
    export_glb(objs, "donut.glb")
    return objs


def build_candy_cane_arch():
    """Striped arch spanning the track: 14 alternating pink/white segments
    on a semicircle (radius 3.4, springing at z=2.6) + 2 poles."""
    clean()
    pink = gloss("CanePink", "#c22a5c", 0.2)
    white = gloss("CaneWhite", "#ffffff", 0.25)
    objs = []
    n = 14
    for i in range(n):
        t0 = math.pi * i / n
        t1 = math.pi * (i + 1) / n
        tm = (t0 + t1) / 2
        p0 = (3.4 * math.cos(t0), 0, 2.6 + 3.4 * math.sin(t0))
        p1 = (3.4 * math.cos(t1), 0, 2.6 + 3.4 * math.sin(t1))
        objs.append(tube_between("Arch%d" % i, p0, p1, 0.16, pink if i % 2 == 0 else white, verts=12))
    for x in (-3.4, 3.4):
        objs.append(tube_between("Pole", (x, 0, 0), (x, 0, 2.6), 0.16, pink, verts=12))
        # white bands on the poles
        for z in (0.7, 1.7):
            objs.append(tube_between("Band", (x, 0, z - 0.15), (x, 0, z + 0.15), 0.17, white, verts=12))
    export_glb(objs, "candy_cane_arch.glb")
    return objs


def build_gummy_bear():
    """Glossy gummy bear, ~1.6 tall. Body material 'Gummy' (recolorable)."""
    clean()
    gummy = gloss("Gummy", "#7ed957", 0.12)
    belly = gloss("Belly", "#ffffff", 0.3)
    objs = []
    body = sphere("Body", 0.5, (0, 0, 0.55), gummy, seg=20, rings=12)
    body.scale = (1, 0.8, 1.15)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    objs.append(body)
    head = sphere("Head", 0.34, (0, 0, 1.25), gummy, seg=20, rings=12)
    objs.append(head)
    for x in (-0.22, 0.22):
        objs.append(sphere("Ear", 0.12, (x, 0, 1.52), gummy, seg=10, rings=6))
    objs.append(sphere("Snout", 0.16, (0, 0.28, 1.18), belly, seg=12, rings=8))
    for x in (-0.42, 0.42):
        objs.append(capsule_z("Arm", 0.11, 0.3, (x, 0, 0.75), gummy))
    for x in (-0.22, 0.22):
        objs.append(capsule_z("Leg", 0.12, 0.25, (x, 0, 0.12), gummy))
    export_glb(objs, "gummy_bear.glb")
    return objs


def build_ice_cream_cone():
    """Waffle cone + pink + white scoops + cherry."""
    clean()
    cone_m = gloss("Cone", "#a87a3e", 0.35)
    pink = gloss("ScoopPink", "#f76fae", 0.2)
    white = gloss("ScoopWhite", "#ffffff", 0.25)
    cherry = gloss("Cherry", "#ff2e4d", 0.1)
    objs = []
    c = cone("Cone", 0.05, 0.70, 1.6, (0, 0, 0.8), cone_m, verts=20)
    objs.append(c)
    objs.append(sphere("Scoop1", 0.75, (0, 0, 1.9), pink, seg=20, rings=12))
    objs.append(sphere("Scoop2", 0.55, (0, 0, 2.5), white, seg=18, rings=10))
    objs.append(sphere("Cherry", 0.18, (0, 0, 3.0), cherry, seg=12, rings=8))
    export_glb(objs, "ice_cream_cone.glb")
    return objs


def build_cupcake():
    """Blue cup + pink frosting swirl + cherry."""
    clean()
    cup = gloss("Cup", "#8ecae6", 0.4)
    frost = gloss("Frosting", "#f76fae", 0.2)
    cherry = gloss("Cherry", "#ff2e4d", 0.1)
    objs = []
    objs.append(cone("Cup", 0.45, 0.55, 1.0, (0, 0, 0.5), cup, verts=20))
    objs.append(sphere("Frost1", 0.60, (0, 0, 1.2), frost, seg=18, rings=10))
    objs.append(sphere("Frost2", 0.45, (0, 0, 1.55), frost, seg=16, rings=10))
    objs.append(sphere("Frost3", 0.28, (0, 0, 1.85), frost, seg=14, rings=8))
    objs.append(sphere("Cherry", 0.15, (0, 0, 2.05), cherry, seg=12, rings=8))
    export_glb(objs, "cupcake.glb")
    return objs


def build_candy_mountain():
    """Pastel candy mountain with white snow cap."""
    clean()
    mtn = gloss("Mountain", "#c9a0dc", 0.5)
    snow = gloss("Snow", "#ffffff", 0.5)
    objs = []
    objs.append(cone("Mountain", 3.2, 0.0, 5.0, (0, 0, 2.5), mtn, verts=24))
    objs.append(cone("SnowCap", 1.25, 0.0, 1.6, (0, 0, 4.6), snow, verts=24))
    objs.append(sphere("SnowBall", 0.8, (0, 0, 5.0), snow, seg=14, rings=8))
    export_glb(objs, "candy_mountain.glb")
    return objs


# ------------------------------------------------------------------- main ---
def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    build_dijah()
    build_tile("a", 11)
    build_tile("b", 23)
    build_hole_tile()
    build_rail("rail_left", "#ff5c8a", "#ffffff")
    build_rail("rail_right", "#5fe3c0", "#ff5c8a")
    build_star()
    build_lollipop()
    build_donut()
    build_candy_cane_arch()
    build_gummy_bear()
    build_ice_cream_cone()
    build_cupcake()
    build_candy_mountain()
    print("ALL MODELS DONE ->", OUT_DIR)


if __name__ == "__main__":
    main()
