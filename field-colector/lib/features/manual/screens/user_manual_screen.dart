import 'package:field_colector/features/utilities/theme/app_colors.dart';
import 'package:field_colector/features/utilities/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Spacing configuration for stacked folder layout
    const double tabHeight = 52.0;

    final List<_ManualCardData> cards = [
      _ManualCardData(
        title: 'Field Collector',
        subtitle: 'Inicio y navegación del manual',
        icon: PhosphorIconsRegular.info,
        baseColor: AppColors.semilleroDarkGreen,
        textColor: Colors.white,
        content: _buildIntroContent(textTheme),
      ),
      _ManualCardData(
        title: 'Mapa',
        subtitle: 'Visualización y filtros de registros',
        icon: PhosphorIconsRegular.mapTrifold,
        baseColor: AppColors.semilleroDeepBlue,
        textColor: Colors.white,
        content: _buildMapContent(textTheme),
      ),
      _ManualCardData(
        title: 'Expediciones',
        subtitle: 'Gestión y sincronización de salidas',
        icon: PhosphorIconsRegular.mountains,
        baseColor: AppColors.semilleroLightGreen,
        textColor: AppColors.semilleroInk,
        content: _buildExpeditionsContent(textTheme),
      ),
      _ManualCardData(
        title: 'Registros',
        subtitle: 'Formularios y toma de datos',
        icon: PhosphorIconsRegular.notePencil,
        baseColor: AppColors.semilleroViolet,
        textColor: Colors.white,
        content: _buildRecordsContent(textTheme),
      ),
      _ManualCardData(
        title: 'Exportación',
        subtitle: 'Descarga de datos en Excel',
        icon: PhosphorIconsRegular.fileXls,
        baseColor: AppColors.semilleroSkyBlue,
        textColor: Colors.white,
        content: _buildExportContent(textTheme),
      ),
      _ManualCardData(
        title: 'Configuraciones',
        subtitle: 'Ajustes del dispositivo y GPS',
        icon: PhosphorIconsRegular.sliders,
        baseColor: AppColors.semilleroMagenta,
        textColor: Colors.white,
        content: _buildSettingsContent(textTheme),
      ),
      _ManualCardData(
        title: 'Cuenta',
        subtitle: 'Perfil y sesión activa',
        icon: PhosphorIconsRegular.user,
        baseColor: AppColors.primary,
        textColor: Colors.white,
        content: _buildAccountContent(textTheme),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.authBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manual de Usuario',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final N = cards.length;

            return Stack(
              children: List.generate(N, (index) {
                final card = cards[index];
                final isSelected = _selectedIndex == index;

                // Spacing logic:
                // Cards <= selectedIndex stack at the top.
                // Cards > selectedIndex stack at the bottom.
                double topPosition;
                if (index <= _selectedIndex) {
                  topPosition = index * tabHeight;
                } else {
                  topPosition = screenHeight - ((N - index) * tabHeight);
                }

                // Dynamic bottom padding to keep scrollable content visible above the bottom stack
                final double bottomPadding =
                    index < _selectedIndex ? 0 : (N - 1 - index) * tabHeight + 24;

                return AnimatedPositioned(
                  key: ValueKey(index),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  top: topPosition,
                  left: 8,
                  right: 8,
                  bottom: isSelected ? 0 : (index > _selectedIndex ? 0 : null),
                  height: !isSelected && index <= _selectedIndex ? tabHeight + 24 : null,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: card.baseColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: tabHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    card.icon,
                                    color: card.textColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      card.title.toUpperCase(),
                                      style: AppStyles.subtitle.copyWith(
                                        color: card.textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  if (!isSelected)
                                    Icon(
                                      index < _selectedIndex
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: card.textColor.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Card Scrollable Content Area (Only if selected/front)
                          if (isSelected)
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: Container(
                                  color: AppColors.cloudWhite,
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(
                                      16,
                                      20,
                                      16,
                                      bottomPadding,
                                    ),
                                    child: card.content,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  // --- Content builders ---

  Widget _buildIntroContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Bienvenido a Field Collector!',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Esta aplicación es una herramienta de recolección de datos georreferenciados '
          'diseñada para funcionar incluso sin conexión a internet.',
          style: AppStyles.body,
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          title: '¿Cómo navegar en este manual?',
          icon: PhosphorIconsRegular.handPointing,
          color: AppColors.semilleroDarkGreen,
          body: 'Las pestañas de colores en el borde superior e inferior representan las '
              'diferentes secciones. Toca cualquiera de ellas para traer la tarjeta al '
              'frente y explorar su contenido de forma interactiva.',
        ),
        const SizedBox(height: 20),
        _buildInfoItem(
          icon: PhosphorIconsRegular.wifiSlash,
          title: 'Funciona sin internet',
          description: 'Los registros tomados en campo se guardan de forma segura en tu '
              'dispositivo. Al recuperar la conexión, se envían automáticamente '
              'al servidor.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: PhosphorIconsRegular.target,
          title: 'Geolocalización Automática',
          description: 'La aplicación utiliza el GPS de tu dispositivo para vincular '
              'coordenadas y altitud de forma precisa a cada registro del ecosistema.',
        ),
      ],
    );
  }

  Widget _buildMapContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exploración en el Mapa',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'El mapa interactivo es el centro de control del colector de campo. Permite ver registros cercanos y orientarte en tiempo real.',
          style: AppStyles.body,
        ),
        const SizedBox(height: 20),
        _buildGuideSection(
          title: 'Elementos Clave del Mapa',
          icon: PhosphorIconsRegular.mapPin,
          color: AppColors.semilleroDeepBlue,
          body: '• Pines de Colores: Cada categoría de registro tiene su propio color.\n'
              '• Radio de 2km: Se muestran los registros subidos en un radio de 2 km a la redonda.\n'
              '• Ubicación: Círculo azul indica tu posición GPS exacta en tiempo real.',
        ),
        const SizedBox(height: 20),
        _buildInfoItem(
          icon: PhosphorIconsRegular.funnel,
          title: 'Filtros Dinámicos',
          description: 'Usa el panel de filtros para ocultar o mostrar categorías '
              '(Aves, Suelos, Rocas, etc.) y limpiar la visualización según tu área de enfoque.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: PhosphorIconsRegular.database,
          title: 'Mapas descargados',
          description: 'Puedes descargar previamente los mapas de la zona '
              'para visualizarlos sin señal de internet.',
        ),
      ],
    );
  }

  Widget _buildExpeditionsContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Expediciones',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Las expediciones organizan las salidas de campo para los miembros '
          'autorizados, permitiendo una toma de datos coordinada.',
          style: AppStyles.body,
        ),
        const SizedBox(height: 24),

        // ── Crear expedición ──
        _buildGuideSection(
          title: 'Crear una Expedición',
          icon: PhosphorIconsRegular.plusCircle,
          color: AppColors.semilleroLightGreen,
          body: 'Si eres coordinador o investigador, puedes crear una nueva '
              'expedición directamente desde la aplicación.',
        ),
        const SizedBox(height: 16),
        _buildStepByStep(
          accentColor: AppColors.semilleroLightGreen,
          steps: [
            _StepData(
              title: 'Abrir pestaña de Expediciones',
              description: 'Desde el panel lateral, entra en la sección '
                  'Expediciones. Verás una barra de búsqueda y un botón "+" '
                  'para crear.',
            ),
            _StepData(
              title: 'Llenar información general',
              description: 'Completa los campos obligatorios: Prefijo (ej. '
                  'EXP-BOY), Nombre, Ubicación, Zona y Razón de la salida.',
              visual: _buildMockCreateFormFields(),
            ),
            _StepData(
              title: 'Seleccionar fechas',
              description: 'Elige la fecha de inicio y de fin de la expedición '
                  'usando los selectores de calendario.',
            ),
            _StepData(
              title: 'Marcar ubicación en mapa',
              description: 'Toca "Seleccionar en mapa" para abrir el mapa '
                  'embebido y fijar las coordenadas exactas (latitud, longitud '
                  'y altitud) del punto de referencia.',
            ),
            _StepData(
              title: 'Crear expedición',
              description: 'Al presionar el botón, se guarda en tu '
                  'dispositivo y se envía al servidor si hay conexión.',
              visual: _buildMockButton(
                label: 'Crear expedición',
                icon: Icons.add_circle_outline,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Unirse a expedición ──
        _buildGuideSection(
          title: 'Unirse a una Expedición',
          icon: PhosphorIconsRegular.usersThree,
          color: AppColors.semilleroLightGreen,
          body: 'Si no eres el creador, puedes solicitar unirte a una '
              'expedición existente.',
        ),
        const SizedBox(height: 16),
        _buildStepByStep(
          accentColor: AppColors.semilleroLightGreen,
          steps: [
            _StepData(
              title: 'Buscar expedición',
              description: 'Usa la barra de búsqueda para encontrar la '
                  'expedición por nombre, prefijo o ubicación.',
            ),
            _StepData(
              title: 'Abrir detalle',
              description: 'Toca la tarjeta de la expedición para ver su '
                  'información completa: director, participantes y fechas.',
              visual: _buildMockExpeditionCard(),
            ),
            _StepData(
              title: 'Solicitar unirse',
              description: 'Presiona "Solicitar unirse". Tu solicitud '
                  'quedará pendiente hasta que el director la apruebe.',
              visual: _buildMockButton(
                label: 'Solicitar unirse',
                icon: Icons.person_add,
                color: AppColors.primary,
              ),
            ),
            _StepData(
              title: 'Activar modo "En campo"',
              description: 'Una vez aprobado, el botón "En campo" se habilita. '
                  'Actívalo para comenzar a tomar registros vinculados a la '
                  'expedición.',
              visual: _buildMockButton(
                label: 'En campo',
                icon: Icons.explore,
                color: AppColors.accent,
                textColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoItem(
          icon: PhosphorIconsRegular.shieldCheck,
          title: 'Permisos de Registro',
          description: 'Solo podrás subir registros vinculados a una '
              'expedición activa de la que seas participante registrado.',
        ),
      ],
    );
  }

  Widget _buildRecordsContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toma de Registros en Campo',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'El corazón del colector. La app cuenta con 6 módulos especializados '
          'para recolectar datos estructurados y enriquecidos.',
          style: AppStyles.body,
        ),
        const SizedBox(height: 20),

        // ── Prerequisito ──
        _buildGuideSection(
          title: '⚠ Requisito previo: Expedición activa',
          icon: PhosphorIconsRegular.warning,
          color: AppColors.accent,
          body: 'Para crear un registro, primero debes estar en modo '
              '"En campo" dentro de una expedición activa. Si no tienes '
              'expedición, ve a la sección Expediciones para crear una o '
              'solicitar unirte.',
        ),
        const SizedBox(height: 24),

        // ── Step-by-step ──
        _buildGuideSection(
          title: 'Crear un Registro',
          icon: PhosphorIconsRegular.notePencil,
          color: AppColors.semilleroViolet,
          body: 'Sigue estos pasos para tomar un registro de campo completo:',
        ),
        const SizedBox(height: 16),
        _buildStepByStep(
          accentColor: AppColors.semilleroViolet,
          steps: [
            _StepData(
              title: 'Activar "En campo"',
              description: 'Desde el detalle de tu expedición, presiona '
                  '"En campo" para vincular tus registros a esa salida.',
            ),
            _StepData(
              title: 'Abrir panel de formularios',
              description: 'En el panel lateral derecho del mapa, accede a '
                  '"Formularios de registro". Verás las categorías disponibles.',
            ),
            _StepData(
              title: 'Seleccionar categoría',
              description: 'Elige entre las categorías usando los chips '
                  'de filtro:',
              visual: _buildMockCategoryChips(),
            ),
            _StepData(
              title: 'Elegir formulario',
              description: 'Selecciona el formulario específico del módulo '
                  'que necesitas. Un punto amarillo indica borrador existente.',
              visual: Column(
                children: [
                  _buildMockFormCatalogItem(
                    title: 'Registro de Aves y Hábitat',
                    formId: 'modulo_aves',
                  ),
                  const SizedBox(height: 8),
                  _buildMockFormCatalogItem(
                    title: 'Registro de Vegetación',
                    formId: 'modulo_vegetacion',
                    hasDraft: true,
                  ),
                ],
              ),
            ),
            _StepData(
              title: 'Llenar el formulario',
              description: 'El formulario tiene dos secciones:\n'
                  '• Datos comunes: municipio, departamento, coordenadas GPS '
                  '(se capturan automáticamente), fotos\n'
                  '• Módulo específico: campos científicos del tipo de registro',
            ),
            _StepData(
              title: 'Guardar registro',
              description: 'Presiona "Guardar registro". Se almacena '
                  'en tu dispositivo y se envía automáticamente al '
                  'servidor cuando haya conexión.',
              visual: _buildMockButton(
                label: 'Guardar registro',
                icon: Icons.save_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── 6 módulos ──
        _buildGuideSection(
          title: 'Los 6 Módulos Especializados',
          icon: PhosphorIconsRegular.tree,
          color: AppColors.semilleroViolet,
          body: '1. Aves: Avistamiento, especie y comportamiento.\n'
              '2. Rocas: Tipo, dureza, estructura y mineralogía.\n'
              '3. Suelos: Textura, pH, color y humedad del suelo.\n'
              '4. Vegetación: Cobertura, tipo de bosque y especies.\n'
              '5. Agua: Calidad, caudal, temperatura y turbidez.\n'
              '6. Social: Observaciones sociales e impactos humanos.',
        ),
        const SizedBox(height: 20),
        _buildInfoItem(
          icon: PhosphorIconsRegular.floppyDisk,
          title: 'Autoguardado de Borradores',
          description: 'Si sales de un formulario a medio llenar, la '
              'aplicación guardará un borrador de forma segura para que '
              'no pierdas nada.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: PhosphorIconsRegular.camera,
          title: 'Captura Fotográfica',
          description: 'Toma fotos directamente de la especie o zona de '
              'estudio. Las imágenes se guardan y se suben al servidor '
              'de forma automática.',
        ),
      ],
    );
  }

  Widget _buildExportContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exportación de Datos',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Genera un archivo Excel (.xlsx) con los registros sincronizados '
          'en el servidor. Puedes filtrar por alcance y rango de fechas, '
          'y compartir el archivo con otras apps.',
          style: AppStyles.body,
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          title: '¿Qué incluye el Excel?',
          icon: PhosphorIconsRegular.table,
          color: AppColors.semilleroSkyBlue,
          body: 'Una hoja por módulo con datos:\n'
              '• Aves\n'
              '• Rocas\n'
              '• Suelos\n'
              '• Vegetación\n'
              '• Agua\n'
              '• Social\n\n'
              'Solo se crean hojas para módulos que tengan registros '
              'en el filtro elegido.',
        ),
        const SizedBox(height: 28),
        _buildGuideSection(
          title: 'Exportar desde Configuraciones',
          icon: PhosphorIconsRegular.sliders,
          color: AppColors.semilleroSkyBlue,
          body: 'Opción avanzada con filtros de alcance y fechas.',
        ),
        const SizedBox(height: 16),
        _buildStepByStep(
          accentColor: AppColors.semilleroSkyBlue,
          steps: [
            _StepData(
              title: 'Abrir panel de Configuraciones',
              description: 'Desde el menú lateral, entra en Configuraciones '
                  'y busca el grupo "Datos".',
              visual: _buildMockExportSettingsTile(),
            ),
            _StepData(
              title: 'Tocar "Exportar datos"',
              description: 'Se abre un panel inferior para elegir alcance '
                  'y, si quieres, un rango de fechas.',
            ),
            _StepData(
              title: 'Elegir alcance',
              description: 'Selecciona una de las opciones:\n'
                  '• Todos: todos los registros accesibles\n'
                  '• Mis registros: solo los tuyos (requiere sesión)\n'
                  '• Por expedición: una salida específica',
              visual: _buildMockExportScopeChips(),
            ),
            _StepData(
              title: 'Filtrar fechas (opcional)',
              description: 'Define "Desde" y "Hasta" para acotar por fecha '
                  'de registro. Si no eliges fechas, se exportan todos '
                  'los del alcance seleccionado.',
            ),
            _StepData(
              title: 'Generar y compartir',
              description: 'Presiona "Generar Excel". La app crea el archivo '
                  'y abre el diálogo de compartir para guardarlo o enviarlo '
                  '(Drive, correo, etc.).',
              visual: _buildMockButton(
                label: 'Generar Excel',
                icon: Icons.file_download_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildGuideSection(
          title: 'Exportar desde una Expedición',
          icon: PhosphorIconsRegular.mountains,
          color: AppColors.semilleroSkyBlue,
          body: 'Atajo rápido: exporta todos los registros de esa '
              'expedición sin configurar filtros extra.',
        ),
        const SizedBox(height: 16),
        _buildStepByStep(
          accentColor: AppColors.semilleroSkyBlue,
          steps: [
            _StepData(
              title: 'Abrir detalle de expedición',
              description: 'Entra a la expedición desde la pestaña '
                  'Expediciones.',
            ),
            _StepData(
              title: 'Exportar registros',
              description: 'Toca el botón "Exportar registros". El archivo '
                  'usará el prefijo de la expedición en el nombre.',
              visual: _buildMockButton(
                label: 'Exportar registros',
                icon: Icons.file_download_outlined,
                color: AppColors.cloudWhite,
                textColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoItem(
          icon: PhosphorIconsRegular.wifiHigh,
          title: 'Requiere conexión',
          description: 'La exportación consulta los datos en el servidor. '
              'Asegúrate de tener internet y de haber sincronizado antes '
              'los registros tomados en campo.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: PhosphorIconsRegular.shareNetwork,
          title: 'Compartir archivo',
          description: 'Al terminar, el sistema te permite guardar el .xlsx '
              'en el dispositivo o enviarlo a otra aplicación.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: PhosphorIconsRegular.warning,
          title: 'Sin datos en el filtro',
          description: 'Si no hay registros que coincidan, verás un mensaje '
              'de error. Prueba ampliar el rango de fechas o cambiar el alcance.',
        ),
      ],
    );
  }

  Widget _buildSettingsContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuraciones y Ajustes',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ajusta el comportamiento de geolocalización, sincronización y '
          'memoria local de tu dispositivo. A continuación se muestran las '
          'configuraciones más importantes:',
          style: AppStyles.body,
        ),
        const SizedBox(height: 24),

        // ── GPS y ubicación ──
        _buildMockSettingsGroup(
          title: 'GPS y ubicación',
          icon: PhosphorIconsRegular.crosshair,
          children: [
            _buildMockSettingsTile(
              title: 'Precisión GPS',
              subtitle: 'Mayor precisión consume más batería',
              value: 'Media',
            ),
            _buildMockSettingsTile(
              title: 'Intervalo de actualización',
              subtitle: 'Frecuencia del seguimiento en mapa',
              value: '22 s',
            ),
            _buildMockSettingsTile(
              title: 'Formato de coordenadas',
              value: 'Decimal',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSettingsExplanation(
          'La precisión GPS determina la exactitud de las coordenadas. '
          'En alta precisión, el consumo de batería aumenta. '
          'El formato puede ser Decimal (5.5353) o '
          'Grados-Minutos-Segundos (5°32\'7.1"N).',
        ),
        const SizedBox(height: 20),

        // ── Mapa ──
        _buildMockSettingsGroup(
          title: 'Mapa',
          icon: PhosphorIconsRegular.mapTrifold,
          children: [
            _buildMockSettingsTile(
              title: 'Zoom inicial',
              value: '15',
            ),
            _buildMockSettingsTile(
              title: 'Mostrar mi ubicación',
              toggleValue: true,
            ),
            _buildMockSettingsTile(
              title: 'Tipo de mapa',
              subtitle: 'Capa base cuando hay conexión',
              value: 'Estándar',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSettingsExplanation(
          'El zoom inicial controla qué tan cercano o lejano se ve el mapa '
          'al abrir la app. "Mostrar mi ubicación" activa el punto azul '
          'GPS en tiempo real.',
        ),
        const SizedBox(height: 20),

        // ── Datos ──
        _buildMockSettingsGroup(
          title: 'Datos',
          icon: PhosphorIconsRegular.cloudArrowUp,
          children: [
            _buildMockSettingsTile(
              title: 'Sincronizar ahora',
              subtitle: 'Todo sincronizado',
              isAction: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSettingsExplanation(
          'Fuerza la subida inmediata de registros, expediciones y fotos '
          'pendientes. Útil cuando acabas de recuperar señal de internet.',
        ),
        const SizedBox(height: 20),

        // ── Almacenamiento ──
        _buildMockSettingsGroup(
          title: 'Almacenamiento',
          icon: PhosphorIconsRegular.hardDrives,
          children: [
            _buildMockSettingsTile(
              title: 'Uso local',
              subtitle: '12.4 MB',
            ),
            _buildMockSettingsTile(
              title: 'Borrar mapas descargados',
              subtitle: 'Mapas guardados para uso sin internet',
              isAction: true,
            ),
            _buildMockSettingsTile(
              title: 'Borrar borradores de formularios',
              isAction: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSettingsExplanation(
          'Libera espacio en tu dispositivo eliminando mapas descargados '
          'o borradores de formularios incompletos. Los registros ya '
          'enviados al servidor no se ven afectados.',
        ),
      ],
    );
  }

  Widget _buildAccountContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de tu Cuenta',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Información del perfil del investigador y control de sesiones seguras.',
          style: AppStyles.body,
        ),
        const SizedBox(height: 20),
        _buildGuideSection(
          title: 'Perfil del Investigador',
          icon: PhosphorIconsRegular.userCircle,
          color: AppColors.primary,
          body: 'Visualiza tus datos básicos, carrera/estudio de campo de origen, '
              'rol organizativo (estudiante, investigador, coordinador) y fecha de registro.',
        ),
        const SizedBox(height: 20),
        _buildInfoItem(
          icon: PhosphorIconsRegular.key,
          title: 'Sesión guardada',
          description: 'Tu sesión se mantiene iniciada de forma segura. '
              'No necesitas iniciar sesión cada vez que abras la app.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: PhosphorIconsRegular.signOut,
          title: 'Cierre de Sesión',
          description: 'El botón de cierre de sesión borrará de forma segura tus datos locales '
              'temporales y te redirigirá a la pantalla de autenticación.',
        ),
      ],
    );
  }

  Widget _buildGuideSection({
    required String title,
    required IconData icon,
    required Color color,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step-by-step tutorial builder ──

  Widget _buildStepByStep({
    required List<_StepData> steps,
    required Color accentColor,
  }) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      steps[i].title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i].description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (steps[i].visual != null) ...[
                      const SizedBox(height: 10),
                      steps[i].visual!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Mock settings group (decorative) ──

  Widget _buildMockSettingsGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: AppStyles.card,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Mock settings tile (decorative) ──

  Widget _buildMockSettingsTile({
    required String title,
    String? subtitle,
    String? value,
    bool? toggleValue,
    bool isAction = false,
  }) {
    Widget? control;
    if (toggleValue != null) {
      control = Switch.adaptive(value: toggleValue, onChanged: null);
    } else if (value != null) {
      control = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ],
      );
    } else if (isAction) {
      control = Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppStyles.caption),
                ],
              ],
            ),
          ),
          if (control != null) control,
        ],
      ),
    );
  }

  // ── Settings explanation text ──

  Widget _buildSettingsExplanation(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ── Mock expedition card (decorative) ──

  Widget _buildMockExpeditionCard() {
    return Container(
      decoration: AppStyles.card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXP-BOY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Expedición Boyacá Centro',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Tunja, Boyacá · Altiplano Cundiboyacense',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  '01 Jun 2026 – 15 Jun 2026',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Sincronizada',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mock form catalog item (decorative) ──

  Widget _buildMockFormCatalogItem({
    required String title,
    required String formId,
    bool hasDraft = false,
  }) {
    return Container(
      decoration: AppStyles.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(PhosphorIconsRegular.fileText, color: AppColors.primary, size: 28),
              if (hasDraft)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(formId, style: AppStyles.caption),
              ],
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  // ── Mock button (decorative) ──

  Widget _buildMockButton({
    required String label,
    required IconData icon,
    required Color color,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mock create-form fields preview (decorative) ──

  Widget _buildMockCreateFormFields() {
    return Container(
      decoration: AppStyles.card,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final field in ['Prefijo *', 'Nombre *', 'Ubicación *', 'Zona *'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      field,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Mock export settings tile (decorative) ──

  Widget _buildMockExportSettingsTile() {
    return Container(
      decoration: AppStyles.card,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exportar datos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Excel personalizado (alcance y fechas)',
                    style: AppStyles.caption,
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.fileXls,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Mock export scope chips (decorative) ──

  Widget _buildMockExportScopeChips() {
    final scopes = [
      ('Todos', true),
      ('Mis registros', false),
      ('Por expedición', false),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, selected) in scopes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  // ── Mock category chips (decorative) ──

  Widget _buildMockCategoryChips() {
    final categories = [
      ('Geológicas', PhosphorIconsRegular.mountains, true),
      ('Hídricas', PhosphorIconsRegular.dropHalf, false),
      ('Biológicas', PhosphorIconsRegular.leaf, false),
      ('Sociales', PhosphorIconsRegular.usersThree, false),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, icon, selected) in categories)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ManualCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color baseColor;
  final Color textColor;
  final Widget content;

  _ManualCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.baseColor,
    required this.textColor,
    required this.content,
  });
}

class _StepData {
  final String title;
  final String description;
  final Widget? visual;

  _StepData({required this.title, required this.description, this.visual});
}
