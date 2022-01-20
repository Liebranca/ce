onTap
  if(IS_HEL(K_LALT)) {
    CE.kbd[K_ALFT]&=~0b111;
    swtty(-1,CE.ctty);

  };
onHel
  CE.cursor.x-=CE.cursor.x>0;
onRel
  None
