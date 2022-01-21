onTap
  if(IS_HEL(K_LALT)) {
    CE.kbd[K_ALFT]&=~0b111;
    swtty(-1,CE.ctty);

  };CE.cursor.x-=CE.cursor.x>0;

onHel
  CE.cursor.x-=CE.cursor.x>0;
onRel
  None
