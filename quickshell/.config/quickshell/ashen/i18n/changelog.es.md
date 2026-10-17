# Cambios

Traducción de las notas de CHANGELOG.md. Solo hace falta la versión actual:
si falta, la bienvenida las enseña en inglés.

## 3.3.1

### Añadido
- La pantalla de bloqueo muestra la onda de la música en su borde superior, en
  reposo y al iniciar sesión -- la misma que dibuja la barra.
- **El instalador pregunta tres cosas primero**, con las flechas: el idioma
  del shell, la distribución del teclado (también llega a la pantalla de
  inicio de sesión) y el idioma del sistema (`locale-gen` + `localectl`;
  mantener el actual es lo predeterminado). `ASHEN_LANG`, `ASHEN_KB` y
  `ASHEN_LOCALE` saltan cada pregunta.
- La bienvenida y las notas de versión salen en tu idioma: las de español,
  alemán y ruso viven en `i18n/changelog.<idioma>.md`; si no, en inglés.

### Cambiado
- **Escritorios.** Contar ventanas ahora es un interruptor para todos los
  estilos en lugar de un estilo propio: Ajustes > Barra > Disposición > Escritorios
  > *Contar ventanas*, o `qs -c ashen ipc call bar ticks`. Los puntos no lo
  usan: las marcas quedarían encima del punto.
- Los escritorios especiales muestran su propio icono (música, discord, notas,
  fav) en todos los estilos salvo kanji, así un punto o un número ya no oculta
  cuál está abierto. En Pac-Man van sin bloque detrás y el abierto se
  convierte en Pac-Man.
- En el estilo de iconos un escritorio vacío muestra un anillo vacío en lugar
  de su número.
- El widget de tiempo de pantalla se parece a los demás widgets: el icono de
  cada aplicación sobre una placa, su tiempo y una barra con su parte del día.
- Más partes del shell hablan tu idioma: la lista de atajos de Ajustes >
  Entrada, los nombres de las píldoras, la bandeja de widgets, sus formas,
  las carpetas del selector y las aplicaciones predeterminadas.

### Arreglado
- **Dos teclados, dos distribuciones.** Hyprland guarda una distribución por
  teclado, y uno que aparecía después (un receptor inalámbrico al despertar,
  un USB, el inicio de sesión) empezaba en la primera mientras el resto
  seguía en la elegida. Ahora todos siguen la elegida, y uno tardío se
  corrige en pocos segundos.
- El instalador fallaba con el cursor: `bibata-cursor-theme` se compila desde
  el código y necesita otro paquete de AUR, así que ahora instala
  `bibata-cursor-theme-bin`. Su línea para reintentar ya no te manda a pedir
  paquetes de AUR a pacman.
- Los widgets del escritorio quedan fuera del interruptor del visualizador:
  apagado, la barra, el panel de música y la pantalla de bloqueo se callan,
  pero los widgets de visualizador y música siguen moviéndose -- cava sigue
  escuchando mientras uno de ellos esté puesto.
- La onda de música de la barra estaba apagada en el estilo isla; ahora se ve
  ahí, entre los platos, igual que entre las píldoras.
- Pac-Man se desliza de escritorio en escritorio como el indicador de los
  demás estilos, en vez de parpadear de una ficha a la siguiente.
- Un fantasma aparece solo donde de verdad hay ventanas: el escritorio que
  acababas de dejar mostraba uno durante un momento.
