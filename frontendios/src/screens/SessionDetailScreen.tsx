/**
 * Écran de détail d'une séance d'entraînement
 * Interface Dashboard avec onglets : Résumé | Graphiques | Laps | Carnet
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  TextInput,
  Alert,
  Dimensions,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../contexts/AuthContext';
import { Activity, activitiesService } from '../services/activitiesService';
import { PlannedSession } from '../services/plansService';
import {
  logbookService,
  LogbookData,
  NutritionItem,
  HydrationItem,
  SessionEquipment,
} from '../services/logbookService';
import GPSMapView, { GPSPoint } from '../components/GPSMapView';
import { NutritionEditor, HydrationEditor, EffortRating, EquipmentSelector } from '../components/logbook';
import {
  PlannedVsActualComparison,
  ComparisonData,
  ZonesChart,
  AdvancedMetrics,
} from '../components/session';
import {
  ElevationChart,
  PowerChart,
  HeartRateChart,
  PaceChart,
  SpeedChart,
  LapsTable,
  // Graphiques running avancés
  PaceGraph,
  CadenceGraph,
  RunningPowerGraph,
  GroundContactTimeGraph,
  VerticalOscillationGraph,
  StrideLengthGraph,
} from '../components/charts';
import { colors, spacing, typography } from '../theme';

// Types
type RootStackParamList = {
  SessionDetail: {
    session: Activity | PlannedSession;
    isPlanned: boolean;
  };
};

type SessionDetailRouteProp = RouteProp<RootStackParamList, 'SessionDetail'>;
type SessionDetailNavigationProp = NativeStackNavigationProp<RootStackParamList, 'SessionDetail'>;

// Constantes
const SCREEN_WIDTH = Dimensions.get('window').width;

// Types d'onglets
type TabType = 'summary' | 'charts' | 'laps' | 'logbook';

const SessionDetailScreen: React.FC = () => {
  const navigation = useNavigation<SessionDetailNavigationProp>();
  const route = useRoute<SessionDetailRouteProp>();
  const { user } = useAuth();
  const { session, isPlanned } = route.params;

  // State
  const [activeTab, setActiveTab] = useState<TabType>('summary');
  const [logbookData, setLogbookData] = useState<LogbookData | null>(null);
  const [isLoadingLogbook, setIsLoadingLogbook] = useState(false);
  const [isSavingLogbook, setIsSavingLogbook] = useState(false);
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({
    effort: true,
    nutrition: true,
    hydration: true,
    equipment: true,
    notes: true,
  });

  // États éditables du logbook
  const [editableNotes, setEditableNotes] = useState('');
  const [editableEffort, setEditableEffort] = useState<number | null>(null);
  const [editableNutrition, setEditableNutrition] = useState<NutritionItem[]>([]);
  const [editableHydration, setEditableHydration] = useState<HydrationItem[]>([]);
  const [editableEquipment, setEditableEquipment] = useState<SessionEquipment>({});

  // État pour les données GPS/record_data
  const [gpsRecordData, setGpsRecordData] = useState<GPSPoint[]>([]);
  const [isLoadingGPS, setIsLoadingGPS] = useState(false);
  const [gpsError, setGpsError] = useState<string | null>(null);
  const [updatedFileData, setUpdatedFileData] = useState<any>(null);

  // Données de la séance
  const activityData = !isPlanned ? (session as Activity) : null;
  const plannedData = isPlanned ? (session as PlannedSession) : null;

  // Initialiser les états éditables
  const initializeEditableStates = (data: LogbookData | null) => {
    setEditableNotes(data?.notes || '');
    setEditableEffort(data?.effortRating || null);
    setEditableNutrition(data?.nutrition?.items || []);
    setEditableHydration(data?.hydration?.items || []);
    setEditableEquipment(data?.equipment || {});
  };

  // Charger les données du logbook
  const loadLogbookData = useCallback(async () => {
    if (isPlanned || !user?.id) return;

    const activity = session as Activity;
    if (!activity.odometer_id) return;

    setIsLoadingLogbook(true);
    try {
      const result = await logbookService.getLogbookByMongoId(user.id, activity.odometer_id);
      if (result.success && result.data) {
        const extractedData = logbookService.extractLogbookData(result.data.logbook_data);
        setLogbookData(extractedData);
        initializeEditableStates(extractedData);
      } else {
        const fileLogbook = logbookService.extractLogbookData(activity);
        if (fileLogbook) {
          setLogbookData(fileLogbook);
          initializeEditableStates(fileLogbook);
        }
      }
    } catch (error) {
      console.error('Error loading logbook:', error);
    } finally {
      setIsLoadingLogbook(false);
    }
  }, [session, isPlanned, user?.id]);

  // Charger les données GPS
  const loadGPSData = useCallback(async (forceReload: boolean = false) => {
    if (isPlanned || !user?.id) return;
    if (gpsRecordData.length > 0 && !forceReload) return;

    const activity = session as Activity;
    if (!activity.date) return;

    setIsLoadingGPS(true);
    setGpsError(null);

    try {
      const activityDate = activity.date.split('T')[0];
      let result = await activitiesService.getActivityGPSData(user.id, activityDate, true);

      if ((!result.recordData || result.recordData.length === 0) && !forceReload) {
        result = await activitiesService.getActivityGPSData(user.id, activityDate, true);
      }

      if (result.success && result.recordData && result.recordData.length > 0) {
        setGpsRecordData(result.recordData);
        if (result.fileData) {
          setUpdatedFileData(result.fileData);
        }
      } else {
        setGpsError('Aucune donnée GPS disponible');
      }
    } catch (error: any) {
      setGpsError(error.message || 'Erreur lors du chargement');
    } finally {
      setIsLoadingGPS(false);
    }
  }, [session, isPlanned, user?.id, gpsRecordData.length]);

  useEffect(() => {
    loadLogbookData();
  }, [loadLogbookData]);

  // Charger GPS quand on va sur les onglets qui en ont besoin (summary, charts, laps)
  useEffect(() => {
    if (activeTab === 'summary' || activeTab === 'charts' || activeTab === 'laps') {
      loadGPSData(false);
    }
  }, [activeTab, loadGPSData]);

  // Sauvegarder le logbook
  const saveLogbook = async () => {
    if (isPlanned || !user?.id) return;

    const activity = session as Activity;
    if (!activity.odometer_id) return;

    setIsSavingLogbook(true);
    try {
      const nutritionTotals = logbookService.calculateNutritionTotals(editableNutrition);
      const hydrationTotal = logbookService.calculateHydrationTotal(editableHydration);

      const dataToSave: Partial<LogbookData> = {
        notes: editableNotes,
        effortRating: editableEffort ?? undefined,
        nutrition: { items: editableNutrition, totals: nutritionTotals },
        hydration: { items: editableHydration, totalVolume: hydrationTotal },
        weather: logbookData?.weather || { temperature: '', conditions: '' },
        equipment: editableEquipment,
      };

      const result = await logbookService.saveLogbook(user.id, {
        sessionId: activity.id,
        mongoId: activity.odometer_id,
        sessionDate: activity.date,
        sessionName: activity.title,
        logbook: dataToSave,
      });

      if (result.success) {
        Alert.alert('Succès', 'Carnet de bord sauvegardé');
      } else {
        Alert.alert('Erreur', result.error || 'Erreur de sauvegarde');
      }
    } catch (error) {
      Alert.alert('Erreur', 'Erreur lors de la sauvegarde');
    } finally {
      setIsSavingLogbook(false);
    }
  };

  // Helpers
  const getDisciplineColor = (): string => {
    switch (session.discipline) {
      case 'cyclisme': return colors.sports.cycling;
      case 'course': return colors.sports.running;
      case 'natation': return colors.sports.swimming;
      default: return colors.primary[500];
    }
  };

  const getDisciplineIcon = (): string => {
    switch (session.discipline) {
      case 'cyclisme': return 'bicycle';
      case 'course': return 'walk';
      case 'natation': return 'water';
      default: return 'fitness';
    }
  };

  const toggleSection = (section: string) => {
    setExpandedSections(prev => ({ ...prev, [section]: !prev[section] }));
  };

  // Formatage vitesse/allure
  const formatSpeedForSport = (speedKmh: number | null | undefined) => {
    if (speedKmh == null || speedKmh <= 0) return null;

    if (session.discipline === 'course') {
      const pace = 60 / speedKmh;
      const min = Math.floor(pace);
      const sec = Math.round((pace - min) * 60);
      return { value: `${min}:${sec.toString().padStart(2, '0')}`, label: 'Allure', unit: '/km' };
    }
    if (session.discipline === 'natation') {
      const pace = 6 / speedKmh;
      const min = Math.floor(pace);
      const sec = Math.round((pace - min) * 60);
      return { value: `${min}:${sec.toString().padStart(2, '0')}`, label: 'Allure', unit: '/100m' };
    }
    return { value: speedKmh.toFixed(1), label: 'Vitesse', unit: 'km/h' };
  };

  // Données fichier
  const fileData = updatedFileData || activityData?.fileData as any;

  // Calcul de la vitesse moyenne corrigée
  // Priorité: 1) avg_speed_moving_kmh du backend, 2) avg_speed * 3.6 si en m/s, 3) avg_speed si déjà en km/h
  const calculateCorrectedSpeed = (): number | null => {
    // 1. Si le backend fournit avg_speed_moving_kmh (vitesse corrigée en km/h), l'utiliser
    if (fileData?.avg_speed_moving_kmh) {
      console.log(`Vitesse moving_kmh du backend: ${fileData.avg_speed_moving_kmh} km/h`);
      return fileData.avg_speed_moving_kmh;
    }

    // 2. Utiliser avg_speed du backend
    // Le backend unifié stocke avg_speed en m/s, mais les anciennes données peuvent être en km/h
    const avgSpeedRaw = fileData?.avg_speed;
    if (avgSpeedRaw != null && avgSpeedRaw > 0) {
      // Heuristique: si < 30, c'est probablement en m/s (course ~3m/s, vélo ~8m/s)
      // Si > 30, c'est probablement déjà en km/h
      if (avgSpeedRaw < 30) {
        // En m/s, convertir en km/h
        const speedKmh = avgSpeedRaw * 3.6;
        console.log(`Vitesse convertie: ${avgSpeedRaw} m/s = ${speedKmh.toFixed(2)} km/h`);
        return speedKmh;
      } else {
        // Déjà en km/h
        console.log(`Vitesse déjà en km/h: ${avgSpeedRaw}`);
        return avgSpeedRaw;
      }
    }

    return null;
  };

  const avgSpeed = calculateCorrectedSpeed();
  const laps = fileData?.all_laps || fileData?.laps || [];

  // ============ RENDER HEADER ============
  const renderHeader = () => (
    <View style={[styles.header, { backgroundColor: getDisciplineColor() }]}>
      <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
        <Icon name="arrow-back" size={24} color={colors.neutral.white} />
      </TouchableOpacity>

      <View style={styles.headerContent}>
        <View style={styles.headerIcon}>
          <Icon name={getDisciplineIcon()} size={28} color={colors.neutral.white} />
        </View>
        <Text style={styles.headerTitle} numberOfLines={2}>{session.title}</Text>
        <Text style={styles.headerDate}>
          {new Date(session.date).toLocaleDateString('fr-FR', {
            weekday: 'long', day: 'numeric', month: 'long',
          })}
        </Text>

        {/* Quick Stats dans le header */}
        {!isPlanned && activityData && (
          <View style={styles.headerQuickStats}>
            {activityData.duration && (
              <View style={styles.headerStat}>
                <Icon name="time-outline" size={14} color="rgba(255,255,255,0.8)" />
                <Text style={styles.headerStatText}>{activityData.duration}</Text>
              </View>
            )}
            {activityData.distance && (
              <View style={styles.headerStat}>
                <Icon name="map-outline" size={14} color="rgba(255,255,255,0.8)" />
                <Text style={styles.headerStatText}>{activityData.distance}</Text>
              </View>
            )}
            {activityData.loadCoggan && (
              <View style={styles.headerStat}>
                <Icon name="flash-outline" size={14} color="rgba(255,255,255,0.8)" />
                <Text style={styles.headerStatText}>TSS {activityData.loadCoggan}</Text>
              </View>
            )}
          </View>
        )}
      </View>
    </View>
  );

  // ============ RENDER TABS ============
  const renderTabs = () => {
    const tabs: { key: TabType; icon: string; label: string }[] = [
      { key: 'summary', icon: 'stats-chart', label: 'Résumé' },
      { key: 'charts', icon: 'analytics', label: 'Graphiques' },
      { key: 'laps', icon: 'flag', label: 'Laps' },
      { key: 'logbook', icon: 'book', label: 'Carnet' },
    ];

    // Pour les séances prévues, ne montrer que Résumé
    const visibleTabs = isPlanned ? tabs.slice(0, 1) : tabs;

    return (
      <View style={styles.tabsContainer}>
        {visibleTabs.map(tab => (
          <TouchableOpacity
            key={tab.key}
            style={[styles.tab, activeTab === tab.key && styles.tabActive]}
            onPress={() => setActiveTab(tab.key)}
          >
            <Icon
              name={tab.icon}
              size={18}
              color={activeTab === tab.key ? colors.primary[600] : colors.neutral.gray[400]}
            />
            <Text style={[styles.tabText, activeTab === tab.key && styles.tabTextActive]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    );
  };

  // ============ RENDER METRIC CARD ============
  const renderMetricCard = (
    label: string,
    value: string | number | null | undefined,
    icon: string,
    unit?: string,
    highlight?: boolean
  ) => {
    if (value == null) return null;
    const displayValue = typeof value === 'number' ? Math.round(value).toString() : value;

    return (
      <View style={[styles.metricCard, highlight && styles.metricCardHighlight]}>
        <Icon name={icon} size={20} color={highlight ? colors.primary[600] : getDisciplineColor()} />
        <Text style={styles.metricValue}>
          {displayValue}
          {unit && <Text style={styles.metricUnit}> {unit}</Text>}
        </Text>
        <Text style={styles.metricLabel}>{label}</Text>
      </View>
    );
  };

  // ============ TAB: SUMMARY ============
  const renderSummaryTab = () => {
    if (isPlanned) {
      return (
        <View style={styles.tabContent}>
          <View style={styles.metricsGrid}>
            {renderMetricCard('Durée estimée', plannedData?.estimatedDuration, 'time-outline')}
            {renderMetricCard('Distance estimée', plannedData?.estimatedDistance, 'map-outline')}
          </View>
          {plannedData?.description && (
            <View style={styles.descriptionCard}>
              <Text style={styles.descriptionTitle}>Instructions</Text>
              <Text style={styles.descriptionText}>{plannedData.description}</Text>
            </View>
          )}
        </View>
      );
    }

    const speedData = formatSpeedForSport(avgSpeed);

    return (
      <View style={styles.tabContent}>
        {/* Métriques principales */}
        <Text style={styles.sectionTitle}>Performance</Text>
        <View style={styles.metricsGrid}>
          {renderMetricCard('Durée', activityData?.duration, 'time-outline', undefined, true)}
          {renderMetricCard('Distance', activityData?.distance, 'map-outline', undefined, true)}
          {speedData && renderMetricCard(speedData.label, speedData.value, 'speedometer-outline', speedData.unit)}
          {renderMetricCard('TSS', activityData?.loadCoggan, 'barbell-outline')}
        </View>

        {/* Métriques secondaires */}
        <View style={styles.metricsGrid}>
          {renderMetricCard('Puissance moy', activityData?.avgWatt, 'flash-outline', 'W')}
          {renderMetricCard('NP', activityData?.normalizedPower, 'pulse-outline', 'W')}
          {renderMetricCard('D+', activityData?.elevationGain, 'trending-up', 'm')}
          {renderMetricCard('Énergie', activityData?.kilojoules, 'battery-charging', 'kJ')}
        </View>

        {/* Métriques avancées par sport */}
        {activityData && (
          <AdvancedMetrics activity={activityData} sportColor={getDisciplineColor()} />
        )}

        {/* Zones simplifiées */}
        {activityData?.zones && activityData.zones.length > 0 && (
          <ZonesChart
            zones={activityData.zones}
            sportColor={getDisciplineColor()}
            title="Répartition par zones"
            showLegend={false}
          />
        )}

        {/* Carte GPS miniature */}
        {!isPlanned && (
          <View style={styles.miniMapSection}>
            <Text style={styles.sectionTitle}>Tracé</Text>
            <GPSMapView
              recordData={gpsRecordData}
              sportColor={getDisciplineColor()}
              height={150}
              showMarkers={false}
              isLoading={isLoadingGPS}
            />
          </View>
        )}

        {/* Notes coach */}
        {activityData?.description && (
          <View style={styles.descriptionCard}>
            <Text style={styles.descriptionTitle}>Notes de l'entraîneur</Text>
            <Text style={styles.descriptionText}>{activityData.description}</Text>
          </View>
        )}
      </View>
    );
  };

  // ============ TAB: CHARTS ============
  const renderChartsTab = () => {
    if (isLoadingGPS) {
      return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary[500]} />
          <Text style={styles.loadingText}>Chargement des données...</Text>
        </View>
      );
    }

    const hasRecordData = gpsRecordData.length > 0;

    return (
      <View style={styles.tabContent}>
        {/* Profil d'altitude */}
        <ElevationChart
          recordData={gpsRecordData}
          elevationGain={activityData?.elevationGain}
          elevationLoss={activityData?.elevationLoss}
        />

        {/* Puissance (cyclisme) */}
        {session.discipline === 'cyclisme' && (
          <>
            <PowerChart
              recordData={gpsRecordData}
              avgPower={activityData?.avgWatt}
              maxPower={activityData?.maxWatt}
              normalizedPower={activityData?.normalizedPower}
            />
            <SpeedChart
              recordData={gpsRecordData}
              avgSpeed={avgSpeed}
              maxSpeed={fileData?.max_speed}
            />
          </>
        )}

        {/* Graphiques Running */}
        {session.discipline === 'course' && (
          <>
            {/* Allure */}
            <PaceGraph
              recordData={gpsRecordData}
              avgPace={speedData?.value}
              bestPace={fileData?.best_pace}
            />

            {/* Fréquence cardiaque - affiché ici pour le running */}
            <HeartRateChart
              recordData={gpsRecordData}
              zones={activityData?.zones}
              avgHr={fileData?.hr_avg}
              maxHr={fileData?.hr_max}
              showLineChart={hasRecordData}
              showZonesPie={!!(activityData?.zones && Array.isArray(activityData.zones) && activityData.zones.length > 0)}
            />

            {/* Cadence */}
            <CadenceGraph
              recordData={gpsRecordData}
              avgCadence={fileData?.cadence_avg}
              maxCadence={fileData?.cadence_max}
            />

            {/* Longueur de foulée */}
            <StrideLengthGraph
              recordData={gpsRecordData}
              avgStrideLength={fileData?.avg_stride_length}
            />

            {/* Puissance de course */}
            <RunningPowerGraph
              recordData={gpsRecordData}
              avgPower={fileData?.power_avg || activityData?.avgWatt}
              maxPower={fileData?.power_max || activityData?.maxWatt}
            />

            {/* Temps de contact au sol (GCT) */}
            <GroundContactTimeGraph
              recordData={gpsRecordData}
              avgGCT={fileData?.avg_ground_contact_time}
            />

            {/* Oscillation verticale */}
            <VerticalOscillationGraph
              recordData={gpsRecordData}
              avgVO={fileData?.avg_vertical_oscillation}
            />

            {/* Profil d'altitude pour running */}
            <ElevationChart
              recordData={gpsRecordData}
              elevationGain={activityData?.elevationGain}
              elevationLoss={activityData?.elevationLoss}
            />
          </>
        )}

        {/* Fréquence cardiaque (pour cyclisme et autres sports) */}
        {session.discipline !== 'course' && (
          <HeartRateChart
            recordData={gpsRecordData}
            zones={activityData?.zones}
            avgHr={fileData?.hr_avg}
            maxHr={fileData?.hr_max}
            showLineChart={hasRecordData}
            showZonesPie={!!(activityData?.zones && Array.isArray(activityData.zones) && activityData.zones.length > 0)}
          />
        )}

        {/* Carte GPS complète */}
        {hasRecordData && (
          <View style={styles.fullMapSection}>
            <Text style={styles.sectionTitle}>Tracé GPS</Text>
            <GPSMapView
              recordData={gpsRecordData}
              sportColor={getDisciplineColor()}
              height={250}
              showMarkers={true}
              isLoading={false}
            />
          </View>
        )}

        {/* Message si pas de données */}
        {!hasRecordData && !isLoadingGPS && (
          <View style={styles.noDataContainer}>
            <Icon name="analytics-outline" size={48} color={colors.neutral.gray[300]} />
            <Text style={styles.noDataText}>
              Pas de données GPS détaillées pour cette séance
            </Text>
          </View>
        )}
      </View>
    );
  };

  // Helper pour speedData dans Charts
  const speedData = formatSpeedForSport(avgSpeed);

  // ============ TAB: LAPS ============
  const renderLapsTab = () => {
    if (isLoadingGPS) {
      return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary[500]} />
          <Text style={styles.loadingText}>Chargement des tours...</Text>
        </View>
      );
    }

    if (!laps || laps.length === 0) {
      return (
        <View style={styles.tabContent}>
          <View style={styles.noDataContainer}>
            <Icon name="flag-outline" size={48} color={colors.neutral.gray[300]} />
            <Text style={styles.noDataTitle}>Aucun tour enregistré</Text>
            <Text style={styles.noDataText}>
              Cette séance ne contient pas de données de tours/segments
            </Text>
          </View>
        </View>
      );
    }

    return (
      <View style={styles.tabContent}>
        <LapsTable
          laps={laps}
          discipline={session.discipline}
        />
      </View>
    );
  };

  // ============ TAB: LOGBOOK ============
  const renderLogbookTab = () => {
    if (isLoadingLogbook) {
      return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.primary[500]} />
          <Text style={styles.loadingText}>Chargement du carnet...</Text>
        </View>
      );
    }

    return (
      <View style={styles.tabContent}>
        {/* Ressenti d'effort */}
        <View style={styles.logbookSection}>
          <TouchableOpacity
            style={styles.sectionHeader}
            onPress={() => toggleSection('effort')}
          >
            <View style={styles.sectionHeaderLeft}>
              <Icon name="fitness" size={20} color={colors.sports.running} />
              <Text style={styles.sectionHeaderTitle}>Ressenti d'effort</Text>
            </View>
            <Icon
              name={expandedSections.effort ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={colors.neutral.gray[400]}
            />
          </TouchableOpacity>
          {expandedSections.effort && (
            <View style={styles.sectionContent}>
              <EffortRating value={editableEffort} onChange={setEditableEffort} />
            </View>
          )}
        </View>

        {/* Notes */}
        <View style={styles.logbookSection}>
          <TouchableOpacity
            style={styles.sectionHeader}
            onPress={() => toggleSection('notes')}
          >
            <View style={styles.sectionHeaderLeft}>
              <Icon name="document-text" size={20} color={colors.primary[500]} />
              <Text style={styles.sectionHeaderTitle}>Notes</Text>
            </View>
            <Icon
              name={expandedSections.notes ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={colors.neutral.gray[400]}
            />
          </TouchableOpacity>
          {expandedSections.notes && (
            <View style={styles.sectionContent}>
              <TextInput
                style={styles.notesInput}
                value={editableNotes}
                onChangeText={setEditableNotes}
                placeholder="Ajoutez vos notes..."
                placeholderTextColor={colors.neutral.gray[400]}
                multiline
                numberOfLines={4}
              />
            </View>
          )}
        </View>

        {/* Nutrition */}
        <View style={styles.logbookSection}>
          <TouchableOpacity
            style={styles.sectionHeader}
            onPress={() => toggleSection('nutrition')}
          >
            <View style={styles.sectionHeaderLeft}>
              <Icon name="nutrition" size={20} color={colors.status.warning} />
              <Text style={styles.sectionHeaderTitle}>Nutrition</Text>
            </View>
            <Icon
              name={expandedSections.nutrition ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={colors.neutral.gray[400]}
            />
          </TouchableOpacity>
          {expandedSections.nutrition && (
            <View style={styles.sectionContent}>
              <NutritionEditor
                items={editableNutrition}
                onItemsChange={setEditableNutrition}
              />
            </View>
          )}
        </View>

        {/* Hydratation */}
        <View style={styles.logbookSection}>
          <TouchableOpacity
            style={styles.sectionHeader}
            onPress={() => toggleSection('hydration')}
          >
            <View style={styles.sectionHeaderLeft}>
              <Icon name="water" size={20} color={colors.sports.swimming} />
              <Text style={styles.sectionHeaderTitle}>Hydratation</Text>
            </View>
            <Icon
              name={expandedSections.hydration ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={colors.neutral.gray[400]}
            />
          </TouchableOpacity>
          {expandedSections.hydration && (
            <View style={styles.sectionContent}>
              <HydrationEditor
                items={editableHydration}
                onItemsChange={setEditableHydration}
              />
            </View>
          )}
        </View>

        {/* Équipement */}
        <View style={styles.logbookSection}>
          <TouchableOpacity
            style={styles.sectionHeader}
            onPress={() => toggleSection('equipment')}
          >
            <View style={styles.sectionHeaderLeft}>
              <Icon name="bicycle" size={20} color={colors.sports.cycling} />
              <Text style={styles.sectionHeaderTitle}>Équipement</Text>
            </View>
            <Icon
              name={expandedSections.equipment ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={colors.neutral.gray[400]}
            />
          </TouchableOpacity>
          {expandedSections.equipment && user?.id && (
            <View style={styles.sectionContent}>
              <EquipmentSelector
                userId={user.id}
                discipline={session.discipline}
                selectedEquipment={editableEquipment}
                onEquipmentChange={setEditableEquipment}
              />
            </View>
          )}
        </View>

        {/* Bouton Sauvegarder */}
        <TouchableOpacity
          style={[styles.saveButton, isSavingLogbook && styles.saveButtonDisabled]}
          onPress={saveLogbook}
          disabled={isSavingLogbook}
        >
          {isSavingLogbook ? (
            <ActivityIndicator size="small" color={colors.neutral.white} />
          ) : (
            <>
              <Icon name="save" size={20} color={colors.neutral.white} />
              <Text style={styles.saveButtonText}>Sauvegarder</Text>
            </>
          )}
        </TouchableOpacity>
      </View>
    );
  };

  // ============ MAIN RENDER ============
  return (
    <View style={styles.container}>
      {renderHeader()}
      {renderTabs()}
      <ScrollView
        style={styles.scrollContent}
        contentContainerStyle={styles.scrollContentInner}
        showsVerticalScrollIndicator={false}
      >
        {activeTab === 'summary' && renderSummaryTab()}
        {activeTab === 'charts' && renderChartsTab()}
        {activeTab === 'laps' && renderLapsTab()}
        {activeTab === 'logbook' && renderLogbookTab()}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  // Header
  header: {
    paddingTop: spacing.xl * 2,
    paddingBottom: spacing.md,
    paddingHorizontal: spacing.md,
  },
  backButton: {
    position: 'absolute',
    top: spacing.xl + spacing.sm,
    left: spacing.md,
    zIndex: 10,
    padding: spacing.xs,
  },
  headerContent: {
    alignItems: 'center',
    marginTop: spacing.md,
  },
  headerIcon: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  headerTitle: {
    ...typography.styles.h3,
    color: colors.neutral.white,
    textAlign: 'center',
    marginBottom: 2,
  },
  headerDate: {
    ...typography.styles.caption,
    color: 'rgba(255,255,255,0.85)',
    textTransform: 'capitalize',
  },
  headerQuickStats: {
    flexDirection: 'row',
    marginTop: spacing.sm,
    gap: spacing.md,
  },
  headerStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  headerStatText: {
    ...typography.styles.caption,
    color: colors.neutral.white,
    fontWeight: '600',
  },
  // Tabs
  tabsContainer: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.sm,
    gap: 4,
  },
  tabActive: {
    borderBottomWidth: 2,
    borderBottomColor: colors.primary[600],
  },
  tabText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    fontWeight: '500',
  },
  tabTextActive: {
    color: colors.primary[600],
    fontWeight: '600',
  },
  // Content
  scrollContent: {
    flex: 1,
  },
  scrollContentInner: {
    paddingBottom: spacing.xl * 2,
  },
  tabContent: {
    padding: spacing.md,
  },
  // Section titles
  sectionTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
    marginBottom: spacing.sm,
    marginTop: spacing.sm,
  },
  // Metrics grid
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  metricCard: {
    width: (SCREEN_WIDTH - spacing.md * 2 - spacing.sm * 3) / 4,
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.sm,
    alignItems: 'center',
  },
  metricCardHighlight: {
    backgroundColor: colors.primary[50],
    borderWidth: 1,
    borderColor: colors.primary[200],
  },
  metricValue: {
    ...typography.styles.label,
    color: colors.secondary[800],
    textAlign: 'center',
    marginTop: 4,
  },
  metricUnit: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  metricLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    textAlign: 'center',
    fontSize: 10,
  },
  // Description card
  descriptionCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginTop: spacing.sm,
  },
  descriptionTitle: {
    ...typography.styles.label,
    color: colors.secondary[700],
    marginBottom: spacing.xs,
  },
  descriptionText: {
    ...typography.styles.body,
    color: colors.secondary[600],
    lineHeight: 20,
  },
  // Mini map
  miniMapSection: {
    marginTop: spacing.sm,
  },
  fullMapSection: {
    marginTop: spacing.md,
  },
  // Loading
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: spacing.xl * 2,
  },
  loadingText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  // No data
  noDataContainer: {
    alignItems: 'center',
    paddingVertical: spacing.xl * 2,
  },
  noDataTitle: {
    ...typography.styles.h4,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  noDataText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
    textAlign: 'center',
    marginTop: spacing.xs,
    paddingHorizontal: spacing.lg,
  },
  // Logbook sections
  logbookSection: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    marginBottom: spacing.sm,
    overflow: 'hidden',
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing.md,
  },
  sectionHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  sectionHeaderTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  sectionContent: {
    padding: spacing.md,
    paddingTop: 0,
  },
  notesInput: {
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    ...typography.styles.body,
    color: colors.secondary[800],
    minHeight: 100,
    textAlignVertical: 'top',
  },
  // Save button
  saveButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary[600],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginTop: spacing.md,
    gap: spacing.sm,
  },
  saveButtonDisabled: {
    backgroundColor: colors.neutral.gray[400],
  },
  saveButtonText: {
    ...typography.styles.label,
    color: colors.neutral.white,
    fontWeight: '600',
  },
});

export default SessionDetailScreen;
