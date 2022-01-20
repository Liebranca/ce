onTap
  if(IS_HEL(K_LALT)) {
    CE.kbd[K_ARGT]&=~0b111;
    swtty(1,CE.ctty);

  };
onHel
  CE.cursor.x+=CE.cursor.x<(CE.wsz.ws_col-1);
onRel
  None
