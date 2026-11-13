"""
Carcasa de medidor Kelvin de cuatro hilos.
Modelo paramétrico en CadQuery: genera STEP compatible con Autodesk Fusion,
STL para impresión 3D y un ensamblaje de referencia.

IMPORTANTE: dimensiones preliminares inferidas de capturas de KiCad;
revisar en archivo .kicad_pcb antes de imprimir.
"""
import cadquery as cq
from cadquery import exporters
from pathlib import Path

OUT = Path(__file__).resolve().parent

# ==========================================================
# PARÁMETROS DE DISEÑO [mm]  (modificables)
# ==========================================================
PCB_LARGO = 70.0            # X, estimado por escala de footprint banana
PCB_ANCHO = 52.0            # Y
PCB_ESPESOR = 1.6          # estándar supuesto, informe lo deja pendiente
PCB_X0 = 4.0
PCB_Y0 = 8.0
PCB_Z0 = 15.5              # plano inferior de PCB

CAJA_X = 82.0
CAJA_Y = 68.0
BASE_Z = 32.0
TAPA_ESPESOR = 3.2
RADIO_EXTERIOR = 4.6
PARED = 2.5
PISO = 2.4

# Centro de las 4 bananas (del dibujo: paso ~12.5 mm)
BANANA_Y = [14.0, 26.5, 39.0, 51.5]
BANANA_Z = 23.0
BANANA_BOCA_DIAM = 8.1     # juego de inserción, sujeto a pieza real
BANANA_COLORES = [(0.9,0.14,0.16), (0.96,0.76,0.13),
                  (0.14,0.58,0.38), (0.14,0.17,0.22)]
BANANA_NOMBRES = ['FORCE+', 'SENSE+', 'SENSE-', 'FORCE-']

# Tornillos autocortantes M2 (agujero piloto; verificar impresora)
TORNILLOS = [(34.0, 4.35), (71.0, 4.35),
             (34.0, 63.65), (71.0, 63.65)]
AGUJERO_BASE_D = 1.65
AGUJERO_TAPA_D = 2.35

# Pasos laterales provisionales; confirmar ubicación sobre PCB
USB_C_Y = 23.0
USB_C_Z = 22.0
USB_C_ANCHO_Y = 9.6
USB_C_ALTO_Z = 4.2
SWITCH_Y = 50.0
SWITCH_Z = 23.0
SWITCH_ANCHO_Y = 11.0
SWITCH_ALTO_Z = 9.0


def caja_redondeada(w, h, alto, radio, z0=0, x0=None, y0=None):
    """Rectangular extrusion with XY-centered extents and filleted vertical edges."""
    if x0 is None: x0 = CAJA_X/2
    if y0 is None: y0 = CAJA_Y/2
    return (cq.Workplane('XY', origin=(x0,y0,z0))
            .rect(w,h).extrude(alto).edges('|Z').fillet(radio))


def tubo_eje_x(y, z, radio, x_ini, longitud):
    return (cq.Workplane('YZ', origin=(x_ini,0,0))
            .center(y,z).circle(radio).extrude(longitud))


def base():
    # Recipiente plástico, fondo y paredes 2.5 mm
    solid = caja_redondeada(CAJA_X, CAJA_Y, BASE_Z, RADIO_EXTERIOR)
    vacio = caja_redondeada(CAJA_X-2*PARED, CAJA_Y-2*PARED,
                            BASE_Z-PISO+1.0, RADIO_EXTERIOR-PARED,
                            z0=PISO)
    solid = solid.cut(vacio)

    # Cuatro bocas Kelvin: en el lateral de entrada x=0
    for y in BANANA_Y:
        solid = solid.cut(tubo_eje_x(y, BANANA_Z, BANANA_BOCA_DIAM/2,
                                    x_ini=-1.0, longitud=PARED+2.0))

    # USB-C y palanca de encendido; ubicación provisional
    usb = (cq.Workplane('XY').box(8, USB_C_ANCHO_Y, USB_C_ALTO_Z)
           .translate((CAJA_X-1.0,USB_C_Y,USB_C_Z)))
    switch = (cq.Workplane('XY').box(8, SWITCH_ANCHO_Y, SWITCH_ALTO_Z)
              .translate((CAJA_X-1.0,SWITCH_Y,SWITCH_Z)))
    solid = solid.cut(usb).cut(switch)

    # 4 torres de tornillo vinculadas a los bordes laterales de la carcasa
    for x,y in TORNILLOS:
        boss = cq.Workplane('XY',origin=(x,y,PISO)).circle(3.15).extrude(BASE_Z-PISO)
        solid = solid.union(boss)
        pilot = cq.Workplane('XY',origin=(x,y,BASE_Z-11)).circle(AGUJERO_BASE_D/2).extrude(12)
        solid = solid.cut(pilot)

    # Cuatro soportes periféricos para placa, sin taladrar la PCB
    # Dos puntos por cada borde largo, contacto de 1-1.5 mm con la placa.
    for x in [39.0, 66.0]:
        for y in [5.6, 62.4]:
            ledge = (cq.Workplane('XY').box(9.5,7.1,3.2)
                     .translate((x,y,PCB_Z0-1.6)))
            solid = solid.union(ledge)

    # Rieles de posicionamiento de batería LiPo (48 x 34 mm reservados)
    # Altura pequeña para no comprimir la envoltura de la celda.
    for x in [25.8,75.8]:
        for y in [15.7,52.3]:
            rail = (cq.Workplane('XY').box(1.8,7.0,2.7)
                    .translate((x,y,PISO+1.35)))
            solid = solid.union(rail)
    return solid


def tapa():
    t = caja_redondeada(CAJA_X,CAJA_Y,TAPA_ESPESOR,RADIO_EXTERIOR,
                       z0=BASE_Z)
    # Orificios pasantes y rebajes para cabeza de tornillo M2
    for x,y in TORNILLOS:
        hole = cq.Workplane('XY',origin=(x,y,BASE_Z-.1)).circle(AGUJERO_TAPA_D/2).extrude(TAPA_ESPESOR+.2)
        t=t.cut(hole)
        head = cq.Workplane('XY',origin=(x,y,BASE_Z+TAPA_ESPESOR-0.9)).circle(2.35).extrude(1.1)
        t=t.cut(head)

    # Letras muy discretas, grabadas 0.28 mm, legibles en impresión 3D
    ztext=BASE_Z+TAPA_ESPESOR-0.30
    try:
        for texto, size, x, y in [
            ('KELVIN', 8.4, 49.2, 40.2),
            ('MEDIDOR 4 HILOS', 3.1, 49.3, 32.1),
            ('Wi-Fi  |  LiPo', 2.7, 49.3, 26.6),
            ('F+', 3.4, 11.0, BANANA_Y[0]),
            ('S+', 3.4, 11.0, BANANA_Y[1]),
            ('S-', 3.4, 11.0, BANANA_Y[2]),
            ('F-', 3.4, 11.0, BANANA_Y[3]),
        ]:
            lettering=(cq.Workplane('XY',origin=(x,y,ztext))
                        .text(texto,size,0.42,font='Liberation Sans',kind='bold',
                              halign='center',valign='center',combine=True))
            t=t.cut(lettering)
    except Exception as exc:
        print('Advertencia al generar texto:',exc)
    # Una tenue línea/ranura decorativa a la derecha de terminales
    groove=(cq.Workplane('XY',origin=(23.5,34.0,BASE_Z+TAPA_ESPESOR-.26))
            .rect(.62,44).extrude(.45))
    t=t.cut(groove)
    return t


def rect_obj(w,h,d,center):
    return cq.Workplane('XY').box(w,h,d).translate(center)


def modelos_referencia():
    # Geometrías simplificadas, solo para comprobar espacios en Fusion.
    parts={}
    parts['PCB estimada 70x52'] = rect_obj(PCB_LARGO,PCB_ANCHO,PCB_ESPESOR,
        (PCB_X0+PCB_LARGO/2, PCB_Y0+PCB_ANCHO/2, PCB_Z0+PCB_ESPESOR/2))
    parts['Bateria LiPo REFERENCIAL'] = rect_obj(48.0,34.0,6.5,(50.8,34.0,7.5))
    # Cuatro conectores banana (plásticos 21.5 x 11.5), eje de enchufe paralelo a X
    for i,y in enumerate(BANANA_Y):
        parts[f'Banana {BANANA_NOMBRES[i]}'] = (
            cq.Workplane('XY').box(21.5,11.3,9.5)
            .translate((PCB_X0+10.75,y,PCB_Z0+PCB_ESPESOR+4.75)))
        parts[f'Anillo {BANANA_NOMBRES[i]}'] = (
            cq.Workplane('YZ',origin=(-0.35,0,0)).center(y,BANANA_Z)
            .circle(4.00).circle(2.40).extrude(.75))
    # Componentes ilustrativos (no son footprints exactos)
    parts['Zocalo ESP01S'] = rect_obj(10.5,10.3,8.5,(64.0,13.8,21.35))
    parts['Modulo ESP01S'] = rect_obj(24.6,14.4,1.3,(59.0,21.0,26.1))
    parts['Conector auxiliar'] = rect_obj(12.8,8.5,9.5,(67.0,53.0,21.85))
    return parts


def exportar():
    b=base(); t=tapa()
    # Sólidos nativos de intercambio CAD, separados para modificación directa en Fusion
    exporters.export(b,str(OUT/'Carcasa_Kelvin_BASE.step'))
    exporters.export(t,str(OUT/'Carcasa_Kelvin_TAPA.step'))
    exporters.export(b,str(OUT/'Carcasa_Kelvin_BASE.stl'),tolerance=0.085,angularTolerance=0.12)
    exporters.export(t,str(OUT/'Carcasa_Kelvin_TAPA.stl'),tolerance=0.085,angularTolerance=0.12)
    print('BASE volume mm3',round(b.val().Volume(),1),'TAPA mm3',round(t.val().Volume(),1))

    ref=modelos_referencia()
    assy=cq.Assembly(name='MEDIDOR_KELVIN_CARCASA')
    assy.add(b,name='01_Base',color=cq.Color(0.13,0.18,0.23))
    assy.add(t,name='02_Tapa',color=cq.Color(0.82,0.86,0.87))
    assy.add(ref['PCB estimada 70x52'],name='03_PCB_dimensional',color=cq.Color(.06,.40,.22))
    assy.add(ref['Bateria LiPo REFERENCIAL'],name='04_Lipo_dimensional',color=cq.Color(.76,.73,.54))
    for i,n in enumerate(BANANA_NOMBRES):
        c=BANANA_COLORES[i]
        assy.add(ref[f'Banana {n}'],name=f'0{i+5}_Conector_{n.replace("+","mas").replace("-","menos")}',color=cq.Color(*c))
        assy.add(ref[f'Anillo {n}'],name=f'1{i}_Anillo_{n.replace("+","mas").replace("-","menos")}',color=cq.Color(*c))
    for i,n in enumerate(['Zocalo ESP01S','Modulo ESP01S','Conector auxiliar']):
        assy.add(ref[n],name=f'2{i}_{n.replace(" ","_")}',color=cq.Color(.10,.12,.15))
    assy.save(str(OUT/'Carcasa_Kelvin_ENSAMBLE.step'),exportType='STEP',mode='default')

    # Imagen de planta para verificación / proceso
    return b,t,ref

if __name__=='__main__':
    exportar()
