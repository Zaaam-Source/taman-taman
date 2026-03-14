# world_renderer.gd — HD v3 — Peta 40×22
extends Node2D

const TS := GameState.TILE_SIZE

const GR_A  := Color(0.22,0.55,0.16); const GR_B  := Color(0.28,0.62,0.20)
const GR_H  := Color(0.35,0.70,0.24); const GR_D  := Color(0.16,0.42,0.10)
const WL_A  := Color(0.38,0.32,0.24); const WL_B  := Color(0.48,0.40,0.30); const WL_D := Color(0.24,0.20,0.14)
const GD_A  := Color(0.36,0.22,0.08); const GD_B  := Color(0.28,0.16,0.05); const GD_H := Color(0.50,0.32,0.14)
const PT_A  := Color(0.74,0.62,0.40); const PT_B  := Color(0.64,0.52,0.32); const PT_D := Color(0.52,0.42,0.26)
const WT_D  := Color(0.14,0.38,0.72); const WT_M  := Color(0.22,0.52,0.88)
const WT_H  := Color(0.44,0.72,1.00); const WT_F  := Color(0.70,0.90,1.00,0.50)
const GRID  := Color(0.0,0.0,0.0,0.04); const HSH  := Color(0.0,0.0,0.0,0.28)
const HW    := Color(0.90,0.80,0.60); const HWS   := Color(0.74,0.62,0.44); const HWH  := Color(0.98,0.92,0.76)
const HR1   := Color(0.68,0.18,0.12); const HR2   := Color(0.58,0.13,0.09); const HR3  := Color(0.80,0.24,0.16)
const HWD   := Color(0.38,0.24,0.10); const HWDH  := Color(0.56,0.38,0.18)
const HGL   := Color(0.66,0.92,0.98,0.80); const HGF := Color(0.78,0.96,1.00,0.40)
const SAW_A := Color(0.88,0.30,0.14); const SAW_B := Color(0.96,0.48,0.22)
const SSGN  := Color(0.96,0.92,0.58); const SSGD  := Color(0.30,0.20,0.06)
const FEN   := Color(0.68,0.48,0.24); const FEND  := Color(0.48,0.32,0.14); const FENH := Color(0.84,0.64,0.38)
const NA_W  := Color(0.92,0.84,0.46); const NA_R1 := Color(0.22,0.52,0.24); const NA_R2 := Color(0.16,0.40,0.18)
const NB_W  := Color(0.72,0.84,0.92); const NB_R1 := Color(0.62,0.22,0.14); const NB_R2 := Color(0.48,0.14,0.10)
const NC_W  := Color(0.88,0.72,0.62); const NC_R1 := Color(0.44,0.32,0.14); const NC_R2 := Color(0.32,0.22,0.08)
const CH_W  := Color(0.72,0.70,0.66); const CH_WS := Color(0.56,0.54,0.50)
const CH_WH := Color(0.86,0.84,0.80); const CH_R  := Color(0.28,0.44,0.22); const CH_RS := Color(0.20,0.34,0.16)
const WS_W  := Color(0.50,0.34,0.18); const WS_WS := Color(0.36,0.24,0.10)
const WS_WH := Color(0.64,0.48,0.28); const WS_R  := Color(0.78,0.60,0.24); const WS_RS := Color(0.60,0.44,0.16)

func _draw() -> void:
	_draw_ground()
	_draw_player_house()
	_draw_npc_house(float(6*TS),  float(1*TS), float(3*TS), float(3*TS), NA_W, NA_R1, NA_R2, float(7*TS)+14)
	_draw_npc_house(float(12*TS), float(1*TS), float(3*TS), float(3*TS), NB_W, NB_R1, NB_R2, float(13*TS)+14)
	_draw_npc_house(float(18*TS), float(1*TS), float(3*TS), float(3*TS), NC_W, NC_R1, NC_R2, float(19*TS)+14)
	_draw_shop()
	_draw_community_hall()
	_draw_workshop()
	_draw_well()
	_draw_garden_fences()
	_draw_trees()
	_draw_grid()

# ══════════════════════════════════════════════════════════════════════════════
#  GROUND TILES
# ══════════════════════════════════════════════════════════════════════════════
func _draw_ground() -> void:
	for row in range(GameState.MAP_ROWS):
		for col in range(GameState.MAP_COLS):
			var t : int = GameState.MAP_DATA[row][col]
			var rx := float(col*TS); var ry := float(row*TS)
			match t:
				GameState.TILE_GRASS:   _tile_grass(rx, ry, (col+row)%2==0)
				GameState.TILE_BLOCKED: _tile_wall(rx, ry, col, row)
				GameState.TILE_GARDEN:  _tile_garden(rx, ry, col, row)
				GameState.TILE_PATH:    _tile_path(rx, ry, (col+row)%3)
				GameState.TILE_DOOR:    _tile_path(rx, ry, 0); _draw_mat(rx, ry)
				GameState.TILE_SHOP:    _tile_path(rx, ry, 1); _draw_counter(rx, ry)
				GameState.TILE_WATER:   _tile_water(rx, ry, col, row)
				_:                      draw_rect(Rect2(rx, ry, TS, TS), GR_A)

func _tile_grass(rx:float, ry:float, alt:bool) -> void:
	var base := GR_A if alt else GR_B
	draw_rect(Rect2(rx, ry, TS, TS), base)
	var sv := int(rx*7+ry*13)%16
	var bc := GR_H if alt else GR_D
	for i in range(3):
		var bx := rx+float((sv*(i+3)*17)%(TS-6))+3.0
		var by2 := ry+float((sv*(i+5)*11)%(TS-10))+4.0
		draw_line(Vector2(bx,by2+4.0),Vector2(bx-1.0,by2),bc,1.2)
		draw_line(Vector2(bx+4.0,by2+4.0),Vector2(bx+5.0,by2+1.0),bc,1.2)

func _tile_wall(rx:float, ry:float, col:int, row:int) -> void:
	draw_rect(Rect2(rx,ry,TS,TS),WL_A)
	var off := 0 if row%2==0 else 16
	for br in range(2):
		var by2 := ry+4+br*28
		var bxs := rx+float((off+br*16)%32)
		draw_rect(Rect2(bxs,by2,28,20),WL_B)
		draw_rect(Rect2(bxs+1,by2+1,26,4),WL_B.lightened(0.15))
		var bx2 := bxs+32
		if bx2 < rx+TS: draw_rect(Rect2(bx2,by2,minf(28.0,rx+TS-bx2),20),WL_B)
	draw_rect(Rect2(rx,ry,3,TS),WL_D); draw_rect(Rect2(rx,ry,TS,3),WL_D)

func _tile_garden(rx:float, ry:float, col:int, row:int) -> void:
	draw_rect(Rect2(rx,ry,TS,TS),GD_A)
	var go := float((col*7+row*3)%8)
	for i in range(4):
		var gx := rx+go+float(i)*14.0
		if gx < rx+TS:
			draw_rect(Rect2(gx,ry+6,3,TS-12),GD_B)
			draw_rect(Rect2(gx+3,ry+6,2,TS-12),GD_H)
	draw_rect(Rect2(rx,ry,TS,6),GD_A.lightened(0.12))
	draw_rect(Rect2(rx,ry+TS-6,TS,6),GD_B)

func _tile_path(rx:float, ry:float, variant:int) -> void:
	draw_rect(Rect2(rx,ry,TS,TS),PT_A)
	if variant==0:
		draw_rect(Rect2(rx+8,ry+TS/2.0-1,TS-16,2),PT_B)
		draw_rect(Rect2(rx+4,ry+TS/2.0+8,TS-8,1),PT_D)
	elif variant==1:
		draw_rect(Rect2(rx,ry+18,TS,2),PT_B); draw_rect(Rect2(rx,ry+44,TS,2),PT_B)
	else:
		draw_rect(Rect2(rx+12,ry+12,8,4),PT_D); draw_rect(Rect2(rx+40,ry+36,10,4),PT_D)
	draw_rect(Rect2(rx,ry,TS,5),PT_A.lightened(0.08))
	draw_rect(Rect2(rx,ry+TS-5,TS,5),PT_D)

func _tile_water(rx:float, ry:float, col:int, row:int) -> void:
	draw_rect(Rect2(rx,ry,TS,TS),WT_D)
	for i in range(3):
		var wy := ry+12.0+float(i)*18.0
		var phase := float((col*3+i*7)%8)
		draw_rect(Rect2(rx+phase,wy,24,3),WT_M)
		draw_rect(Rect2(rx+phase+28,wy,16,3),WT_M)
		draw_rect(Rect2(rx+phase+8,wy+1,8,1),WT_H)
	var s := (col*11+row*7)%6
	draw_circle(Vector2(rx+16+s*6,ry+20),3.0,WT_F)
	draw_circle(Vector2(rx+42-s*4,ry+44),2.5,WT_F)
	draw_rect(Rect2(rx,ry,TS,4),WT_D.darkened(0.2))

func _draw_mat(rx:float, ry:float) -> void:
	draw_rect(Rect2(rx+10,ry+38,44,18),Color(0.55,0.35,0.12))
	draw_rect(Rect2(rx+12,ry+40,40,14),Color(0.44,0.26,0.08))
	for i in range(4): draw_rect(Rect2(rx+12+i*10,ry+40,2,14),Color(0.62,0.42,0.18))

func _draw_counter(rx:float, ry:float) -> void:
	draw_rect(Rect2(rx+4,ry+8,TS-8,TS-16),Color(0.50,0.70,0.52))
	draw_rect(Rect2(rx+6,ry+10,TS-12,14),Color(0.65,0.86,0.66))
	draw_circle(Vector2(rx+20,ry+22),6.0,Color(0.90,0.78,0.20))
	draw_circle(Vector2(rx+44,ry+22),5.0,Color(0.28,0.68,0.24))

# ── Window helper ─────────────────────────────────────────────────────────────
func _draw_window(wx:float, wy:float) -> void:
	draw_rect(Rect2(wx-4,wy-4,52,46),HWS)
	draw_rect(Rect2(wx,wy,44,38),Color(0.32,0.22,0.12))
	draw_rect(Rect2(wx+3,wy+3,38,32),HGL)
	draw_rect(Rect2(wx+4,wy+4,8,6),HGF)
	draw_rect(Rect2(wx+3,wy+19,38,3),Color(0.32,0.22,0.12))
	draw_rect(Rect2(wx+22,wy+3,3,32),Color(0.32,0.22,0.12))
	draw_rect(Rect2(wx-4,wy+42,52,4),HWH)

# ── Roof strips helper ────────────────────────────────────────────────────────
func _draw_roof(x:float, y:float, w:float, h:float, r1:Color, r2:Color, rh:Color) -> void:
	var rx0 := x-14.0; var ry0 := y-h*0.5; var rw0 := w+28.0
	for i in range(4):
		var sw := rw0-float(i)*28.0; var sx := rx0+float(i)*14.0
		var sy := ry0+float(i)*(h*0.5/4.0)
		var rc : Color = r1 if i%2==0 else r2
		draw_rect(Rect2(sx,sy,sw,h*0.5/4.0+6),rc)
		draw_rect(Rect2(sx,sy+h*0.5/4.0,sw,4),r2)
		draw_rect(Rect2(sx+4,sy+2,sw-8,4),rh)
		for nx in range(0,int(sw),18): draw_rect(Rect2(sx+float(nx),sy,3,6),r2)
	draw_rect(Rect2(rx0-4,y-6,rw0+8,8),HWS)
	draw_rect(Rect2(rx0-4,y-6,rw0+8,3),HWH)

# ══════════════════════════════════════════════════════════════════════════════
#  RUMAH PEMAIN (cols 1–3, rows 1–3)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_player_house() -> void:
	var x := float(1*TS); var y := float(1*TS); var w := float(3*TS); var h := float(3*TS)
	draw_rect(Rect2(x+8,y+h+2,w+10,12),HSH)
	draw_rect(Rect2(x,y,w,h),HW)
	for i in range(5):
		var ly := y+10.0+float(i)*34.0
		if ly < y+h-6: draw_rect(Rect2(x+4,ly,w-8,2),HWH)
	draw_rect(Rect2(x+w-10,y,10,h),HWS); draw_rect(Rect2(x,y,w,8),HWS)
	# Cerobong
	draw_rect(Rect2(x+20,y-52,22,52),Color(0.60,0.55,0.50))
	draw_rect(Rect2(x+18,y-56,26,8),Color(0.44,0.40,0.36))
	draw_rect(Rect2(x+20,y-52,4,52),Color(1,1,1,0.12))
	draw_circle(Vector2(x+32,y-62),6.0,Color(0.85,0.85,0.85,0.35))
	_draw_roof(x,y,w,h,HR1,HR2,HR3)
	_draw_window(x+10,y+22); _draw_window(x+w-54,y+22)
	var dx := x+float(TS)+14.0; var dy := y+h-52.0
	draw_rect(Rect2(dx-4,dy-4,44,56),HWDH)
	draw_rect(Rect2(dx,dy,36,52),HWD)
	draw_rect(Rect2(dx+4,dy+4,14,20),HGL); draw_rect(Rect2(dx+20,dy+4,12,20),HGL)
	draw_rect(Rect2(dx+5,dy+5,4,10),HGF)
	draw_circle(Vector2(dx+31,dy+34),5.0,Color(0.85,0.72,0.12))
	draw_circle(Vector2(dx+31,dy+34),3.0,Color(1.00,0.90,0.30))

# ══════════════════════════════════════════════════════════════════════════════
#  NPC HOUSE (generic: kuning/hijau/koral)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_npc_house(x:float, y:float, w:float, h:float,
		wall:Color, roof1:Color, roof2:Color, door_x:float) -> void:
	draw_rect(Rect2(x+8,y+h+2,w+10,12),HSH)
	draw_rect(Rect2(x,y,w,h),wall)
	for i in range(5):
		var ly := y+10.0+float(i)*34.0
		if ly < y+h-6: draw_rect(Rect2(x+4,ly,w-8,2),wall.lightened(0.14))
	draw_rect(Rect2(x+w-10,y,10,h),wall.darkened(0.18))
	_draw_roof(x,y,w,h,roof1,roof2,roof1.lightened(0.2))
	_draw_window(x+10,y+22); _draw_window(x+w-54,y+22)
	var dy := y+h-48.0
	draw_rect(Rect2(door_x-4,dy-4,44,52),HWDH)
	draw_rect(Rect2(door_x,dy,36,48),HWD)
	draw_rect(Rect2(door_x+4,dy+4,14,18),HGL); draw_rect(Rect2(door_x+20,dy+4,12,18),HGL)
	draw_circle(Vector2(door_x+31,dy+30),5.0,Color(0.85,0.72,0.12))

# ══════════════════════════════════════════════════════════════════════════════
#  TOKO (cols 26–30, rows 1–4)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_shop() -> void:
	var x := float(26*TS); var y := float(1*TS); var w := float(5*TS); var h := float(4*TS)
	draw_rect(Rect2(x+8,y+h+2,w+10,12),HSH)
	draw_rect(Rect2(x,y,w,h),Color(0.52,0.74,0.54))
	for i in range(7):
		var ly := y+4.0+float(i)*28.0
		if ly+28 < y+h:
			draw_rect(Rect2(x,ly,w,22),Color(0.52,0.74,0.54).lightened(0.05*(i%2)))
			draw_rect(Rect2(x+3,ly+2,w-6,4),Color(0.70,0.90,0.70))
			draw_rect(Rect2(x,ly+22,w,6),Color(0.38,0.58,0.40))
	draw_rect(Rect2(x+w-8,y,8,h),Color(0.38,0.58,0.40))
	var aw_y := y-32.0
	draw_rect(Rect2(x-14,aw_y,w+28,32),SAW_A)
	for i in range(0,int(w+28),22): draw_rect(Rect2(x-14+float(i),aw_y,11,32),SAW_B)
	for i in range(0,int(w+28),8): draw_rect(Rect2(x-14+float(i),aw_y+28,4,10),SAW_A.darkened(0.15))
	draw_rect(Rect2(x+20,y+10,w-40,48),SSGN)
	draw_rect(Rect2(x+22,y+12,w-44,44),Color(0.88,0.82,0.42))
	draw_rect(Rect2(x+22,y+12,w-44,5),Color(1.00,0.96,0.66))
	draw_rect(Rect2(x+18,y+8,w-36,4),Color(0.50,0.38,0.16))
	draw_rect(Rect2(x+18,y+56,w-36,4),Color(0.50,0.38,0.16))
	_draw_text_toko(x+40,y+28)
	_draw_window(x+16,y+66); _draw_window(x+w-60,y+66)
	draw_circle(Vector2(x+38,y+92),9.0,Color(0.85,0.70,0.12))
	draw_circle(Vector2(x+56,y+90),7.0,Color(0.28,0.68,0.24))

func _draw_text_toko(sx:float, sy:float) -> void:
	draw_rect(Rect2(sx,sy,14,3),SSGD); draw_rect(Rect2(sx+5,sy,4,20),SSGD)
	draw_rect(Rect2(sx+18,sy,14,20),SSGD); draw_rect(Rect2(sx+20,sy+3,10,14),SSGN)
	draw_rect(Rect2(sx+36,sy,4,20),SSGD); draw_rect(Rect2(sx+40,sy+3,10,4),SSGD)
	draw_rect(Rect2(sx+40,sy+11,10,9),SSGD)
	draw_rect(Rect2(sx+54,sy,14,20),SSGD); draw_rect(Rect2(sx+56,sy+3,10,14),SSGN)

# ══════════════════════════════════════════════════════════════════════════════
#  BALAI DESA (cols 2–6, rows 15–17)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_community_hall() -> void:
	var x := float(2*TS); var y := float(15*TS); var w := float(5*TS); var h := float(3*TS)
	draw_rect(Rect2(x+8,y+h+2,w+10,14),HSH)
	draw_rect(Rect2(x,y,w,h),CH_W)
	for row in range(5):
		var ry := y+6.0+float(row)*36.0
		var off2 := 0.0 if row%2==0 else 18.0
		for col in range(0,int(w),36):
			var bx := x+off2+float(col)
			if bx < x+w:
				var bw := minf(34.0,x+w-bx)
				draw_rect(Rect2(bx,ry,bw,28),CH_WH)
				draw_rect(Rect2(bx+1,ry+1,bw-2,4),Color(1,1,1,0.15))
				draw_rect(Rect2(bx+1,ry+26,bw-2,2),CH_WS)
	draw_rect(Rect2(x+w-8,y,8,h),CH_WS); draw_rect(Rect2(x,y,w,6),CH_WS)
	draw_rect(Rect2(x-10,y-22,w+20,28),CH_R)
	draw_rect(Rect2(x-10,y-22,w+20,8),CH_R.lightened(0.15))
	draw_rect(Rect2(x-10,y+4,w+20,6),CH_RS)
	for i in range(0,int(w+20),24): draw_rect(Rect2(x-10+float(i),y-22,3,28),CH_RS)
	for px2 in [x+16.0, x+w/2-6.0, x+w-26.0]:
		draw_rect(Rect2(px2,y,12,h),CH_WH)
		draw_rect(Rect2(px2,y-6,14,8),CH_W)
		draw_rect(Rect2(px2,y+h-6,14,8),CH_W)
	_draw_window(x+4,y+20); _draw_window(x+w-48,y+20)
	var ddx := x+w/2-40
	draw_rect(Rect2(ddx-6,y+h-62,86,66),CH_WS)
	draw_rect(Rect2(ddx,y+h-58,34,58),HWD)
	draw_rect(Rect2(ddx+40,y+h-58,34,58),HWD)
	draw_rect(Rect2(ddx+2,y+h-56,30,26),HGL)
	draw_rect(Rect2(ddx+42,y+h-56,30,26),HGL)
	draw_rect(Rect2(ddx+3,y+h-55,8,12),HGF)
	draw_rect(Rect2(ddx+43,y+h-55,8,12),HGF)
	draw_circle(Vector2(ddx+34,y+h-22),5.0,Color(0.85,0.72,0.12))
	draw_circle(Vector2(ddx+40,y+h-22),5.0,Color(0.85,0.72,0.12))

# ══════════════════════════════════════════════════════════════════════════════
#  LUMBUNG / WORKSHOP (cols 10–14, rows 15–17)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_workshop() -> void:
	var x := float(10*TS); var y := float(15*TS); var w := float(5*TS); var h := float(3*TS)
	draw_rect(Rect2(x+8,y+h+2,w+10,14),HSH)
	draw_rect(Rect2(x,y,w,h),WS_W)
	for i in range(6):
		var ly := y+4.0+float(i)*30.0
		if ly+30 < y+h:
			draw_rect(Rect2(x,ly,w,24),WS_W.lightened(0.06*(i%2)))
			draw_rect(Rect2(x+3,ly+3,w-6,5),WS_WH)
			draw_rect(Rect2(x,ly+24,w,6),WS_WS)
	draw_rect(Rect2(x+w-8,y,8,h),WS_WS)
	var rx0 := x-8.0; var rw0 := w+16.0
	draw_rect(Rect2(rx0,y-28,rw0,32),WS_R)
	draw_rect(Rect2(rx0-4,y-2,rw0+8,8),WS_RS)
	draw_rect(Rect2(rx0,y-28,rw0,6),WS_R.lightened(0.15))
	for i in range(0,int(rw0),10): draw_rect(Rect2(rx0+float(i),y-28,2,32),WS_RS)
	_draw_window(x+14,y+22); _draw_window(x+w-58,y+22)
	var bdx := x+w/2-36
	draw_rect(Rect2(bdx-4,y+h-70,80,74),WS_WS)
	draw_rect(Rect2(bdx,y+h-66,34,66),WS_W.darkened(0.1))
	draw_rect(Rect2(bdx+36,y+h-66,34,66),WS_W.darkened(0.1))
	draw_rect(Rect2(bdx-6,y+h-70,84,5),WS_WS.darkened(0.2))
	draw_line(Vector2(bdx,y+h-66),Vector2(bdx+34,y+h-4),WS_WS,3.0)
	draw_line(Vector2(bdx+34,y+h-66),Vector2(bdx,y+h-4),WS_WS,3.0)
	draw_line(Vector2(bdx+36,y+h-66),Vector2(bdx+70,y+h-4),WS_WS,3.0)
	draw_line(Vector2(bdx+70,y+h-66),Vector2(bdx+36,y+h-4),WS_WS,3.0)

# ══════════════════════════════════════════════════════════════════════════════
#  SUMUR (col 20, row 12)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_well() -> void:
	var cx := float(20*TS+TS/2); var cy := float(12*TS+TS/2)
	draw_rect(Rect2(cx-28,cy+26,56,10),HSH)
	draw_rect(Rect2(cx-28,cy-18,56,44),Color(0.44,0.40,0.34))
	draw_rect(Rect2(cx-26,cy-16,52,42),Color(0.60,0.56,0.50))
	for i in range(3):
		draw_rect(Rect2(cx-26,cy-10+float(i)*12,52,10),Color(0.68,0.62,0.54))
		draw_rect(Rect2(cx-26,cy-10+float(i)*12,52,2),Color(0.74,0.70,0.62))
	draw_rect(Rect2(cx-18,cy-12,36,24),Color(0.18,0.28,0.44))
	draw_rect(Rect2(cx-16,cy-10,32,20),Color(0.22,0.40,0.68,0.80))
	draw_rect(Rect2(cx-16,cy-10,16,4),Color(0.44,0.68,0.88,0.40))
	draw_rect(Rect2(cx-22,cy-40,8,24),Color(0.44,0.28,0.10))
	draw_rect(Rect2(cx+14,cy-40,8,24),Color(0.44,0.28,0.10))
	draw_rect(Rect2(cx-22,cy-40,3,24),Color(0.62,0.44,0.22))
	draw_rect(Rect2(cx-24,cy-42,48,8),Color(0.50,0.34,0.14))
	draw_rect(Rect2(cx-24,cy-42,48,3),Color(0.68,0.52,0.28))
	draw_circle(Vector2(cx,cy-38),10.0,Color(0.44,0.32,0.14))
	draw_circle(Vector2(cx,cy-38),7.0,Color(0.60,0.46,0.22))
	draw_circle(Vector2(cx,cy-38),4.0,Color(0.44,0.32,0.14))
	draw_line(Vector2(cx,cy-32),Vector2(cx,cy-14),Color(0.30,0.22,0.10),2.0)
	draw_rect(Rect2(cx-8,cy-14,16,14),Color(0.52,0.38,0.16))
	draw_rect(Rect2(cx-8,cy-14,16,4),Color(0.68,0.52,0.28))
	draw_rect(Rect2(cx-6,cy-10,12,10),Color(0.28,0.52,0.76,0.70))

# ══════════════════════════════════════════════════════════════════════════════
#  PAGAR KEBUN
# ══════════════════════════════════════════════════════════════════════════════
func _draw_garden_fences() -> void:
	_draw_fence(float(4*TS),float(6*TS),float(13*TS),float(3*TS))
	_draw_fence(float(28*TS),float(6*TS),float(9*TS),float(3*TS))
	_draw_fence(float(28*TS),float(15*TS),float(9*TS),float(3*TS))

func _draw_fence(gx:float, gy:float, gw:float, gh:float) -> void:
	draw_rect(Rect2(gx,gy+gh,gw,8),HSH)
	draw_rect(Rect2(gx,gy-10,gw,14),FEN); draw_rect(Rect2(gx,gy-10,gw,4),FENH)
	draw_rect(Rect2(gx,gy+gh-6,gw,14),FEN); draw_rect(Rect2(gx,gy+gh-6,gw,4),FENH)
	draw_rect(Rect2(gx,gy+gh/2-5,gw,10),FEN); draw_rect(Rect2(gx,gy+gh/2-5,gw,3),FENH)
	for i in range(0,int(gw)+1,TS):
		var tx := gx+float(i)
		draw_rect(Rect2(tx-7,gy-18,14,gh+36),FEND)
		draw_rect(Rect2(tx-5,gy-18,4,gh+36),FENH)
		draw_rect(Rect2(tx-7,gy-22,14,6),FEND)
		draw_rect(Rect2(tx-4,gy-26,8,6),FEN)
		draw_rect(Rect2(tx-2,gy-30,4,6),FEND)

# ══════════════════════════════════════════════════════════════════════════════
#  POHON
# ══════════════════════════════════════════════════════════════════════════════
func _draw_trees() -> void:
	var positions : Array = [
		[4,11],[8,13],[32,11],[36,13],
		[33,5],[36,5],[35,9],[22,9],
		[4,19],[6,20],[30,19],[35,20],
		[21,2],[23,2],[37,12]
	]
	for pos in positions:
		_draw_tree(float(pos[0])*TS+TS/2.0, float(pos[1])*TS+TS*0.8)

func _draw_tree(cx:float, cy:float) -> void:
	draw_rect(Rect2(cx-20,cy+6,40,10),HSH)
	draw_rect(Rect2(cx-7,cy-20,14,28),Color(0.46,0.30,0.12))
	draw_rect(Rect2(cx-7,cy-20,4,28),Color(0.62,0.44,0.22))
	draw_rect(Rect2(cx-14,cy+6,10,4),Color(0.46,0.30,0.12))
	draw_rect(Rect2(cx+4,cy+6,10,4),Color(0.46,0.30,0.12))
	draw_circle(Vector2(cx,cy-42),32.0,Color(0.14,0.42,0.10))
	draw_circle(Vector2(cx,cy-48),28.0,Color(0.20,0.56,0.14))
	draw_circle(Vector2(cx-10,cy-44),20.0,Color(0.22,0.60,0.16))
	draw_circle(Vector2(cx+8,cy-46),22.0,Color(0.18,0.52,0.12))
	draw_circle(Vector2(cx-6,cy-56),14.0,Color(0.32,0.72,0.22))
	draw_circle(Vector2(cx-8,cy-58),8.0,Color(0.40,0.82,0.28))
	for i in range(3):
		var ang := float(i)*2.1
		draw_circle(Vector2(cx+cos(ang)*20.0,cy-44.0+sin(ang)*14.0),4.0,Color(0.90,0.26,0.14))
		draw_circle(Vector2(cx+cos(ang)*20.0,cy-44.0+sin(ang)*14.0),3.0,Color(1.00,0.40,0.22))

# ══════════════════════════════════════════════════════════════════════════════
#  GRID
# ══════════════════════════════════════════════════════════════════════════════
func _draw_grid() -> void:
	for col in range(GameState.MAP_COLS+1):
		draw_line(Vector2(col*TS,0),Vector2(col*TS,GameState.MAP_ROWS*TS),GRID)
	for row in range(GameState.MAP_ROWS+1):
		draw_line(Vector2(0,row*TS),Vector2(GameState.MAP_COLS*TS,row*TS),GRID)
