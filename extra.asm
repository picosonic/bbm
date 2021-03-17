; Extra data

; Horizontal flip look up table
.flip_lut
  EQUB &00, &08, &04, &0c, &02, &0a, &06, &0e, &01, &09, &05, &0d, &03, &0b, &07, &0f
  EQUB &80, &88, &84, &8c, &82, &8a, &86, &8e, &81, &89, &85, &8d, &83, &8b, &87, &8f
  EQUB &40, &48, &44, &4c, &42, &4a, &46, &4e, &41, &49, &45, &4d, &43, &4b, &47, &4f
  EQUB &c0, &c8, &c4, &cc, &c2, &ca, &c6, &ce, &c1, &c9, &c5, &cd, &c3, &cb, &c7, &cf
  EQUB &20, &28, &24, &2c, &22, &2a, &26, &2e, &21, &29, &25, &2d, &23, &2b, &27, &2f
  EQUB &a0, &a8, &a4, &ac, &a2, &aa, &a6, &ae, &a1, &a9, &a5, &ad, &a3, &ab, &a7, &af
  EQUB &60, &68, &64, &6c, &62, &6a, &66, &6e, &61, &69, &65, &6d, &63, &6b, &67, &6f
  EQUB &e0, &e8, &e4, &ec, &e2, &ea, &e6, &ee, &e1, &e9, &e5, &ed, &e3, &eb, &e7, &ef
  EQUB &10, &18, &14, &1c, &12, &1a, &16, &1e, &11, &19, &15, &1d, &13, &1b, &17, &1f
  EQUB &90, &98, &94, &9c, &92, &9a, &96, &9e, &91, &99, &95, &9d, &93, &9b, &97, &9f
  EQUB &50, &58, &54, &5c, &52, &5a, &56, &5e, &51, &59, &55, &5d, &53, &5b, &57, &5f
  EQUB &d0, &d8, &d4, &dc, &d2, &da, &d6, &de, &d1, &d9, &d5, &dd, &d3, &db, &d7, &df
  EQUB &30, &38, &34, &3c, &32, &3a, &36, &3e, &31, &39, &35, &3d, &33, &3b, &37, &3f
  EQUB &b0, &b8, &b4, &bc, &b2, &ba, &b6, &be, &b1, &b9, &b5, &bd, &b3, &bb, &b7, &bf
  EQUB &70, &78, &74, &7c, &72, &7a, &76, &7e, &71, &79, &75, &7d, &73, &7b, &77, &7f
  EQUB &f0, &f8, &f4, &fc, &f2, &fa, &f6, &fe, &f1, &f9, &f5, &fd, &f3, &fb, &f7, &ff

; Flipped sprite buffer
.flip_upper
  SKIP 32 ; Top half of flipped sprite
.flip_lower
  SKIP 32 ; Bottom half of flipped sprite

; Animation frames
.HUMAN_ANIM
  EQUB &10, &11, &12, &11
.BOMBER_ANIM
  EQUB &00, &01, &02, &01 ; Walk
  EQUB &03, &04, &05, &04 ; Climb facing
  EQUB &06, &07, &08, &07 ; Climb away
  EQUB &09, &0A, &0B, &0C, &0D, &0E, &0F ; Explode
