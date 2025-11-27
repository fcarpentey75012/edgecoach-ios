/**
 * Écran liste des séances par discipline
 */

import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation, useRoute, RouteProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../contexts/AuthContext';
import { RootStackParamList } from '../navigation/types';
import { colors, spacing, typography } from '../theme';
import {
  dashboardService,
  activitiesService,
  SessionDetail,
  DisciplineType,
  Activity,
} from '../services';

type DisciplineSessionsRouteProp = RouteProp<RootStackParamList, 'DisciplineSessions'>;
type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

const DisciplineSessionsScreen: React.FC = () => {
  const navigation = useNavigation<NavigationProp>();
  const route = useRoute<DisciplineSessionsRouteProp>();
  const { user } = useAuth();
  const { discipline, weekStart } = route.params;

  const [sessions, setSessions] = useState<SessionDetail[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loadingSessionId, setLoadingSessionId] = useState<string | null>(null);

  // Charger les séances
  const loadSessions = useCallback(async () => {
    if (!user?.id) return;

    try {
      setError(null);
      const result = await dashboardService.getSessionsByDiscipline(
        user.id,
        discipline,
        weekStart
      );

      if (result.success && result.data) {
        setSessions(result.data.sessions);
      } else {
        setError(result.error || 'Erreur de chargement');
      }
    } catch (err) {
      setError('Erreur lors du chargement des séances');
    } finally {
      setLoading(false);
    }
  }, [user?.id, discipline, weekStart]);

  useEffect(() => {
    loadSessions();
  }, [loadSessions]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadSessions();
    setRefreshing(false);
  }, [loadSessions]);

  // Configurer le header
  useEffect(() => {
    navigation.setOptions({
      title: dashboardService.getDisciplineName(discipline),
      headerBackTitle: 'Retour',
    });
  }, [navigation, discipline]);

  // Obtenir la couleur de la discipline
  const getDisciplineColor = (disc: DisciplineType): string => {
    const colorMap: Record<DisciplineType, string> = {
      cyclisme: colors.sports.cycling,
      course: colors.sports.running,
      natation: colors.sports.swimming,
      autre: colors.neutral.gray[500],
    };
    return colorMap[disc];
  };

  // Formater la date
  const formatDate = (dateStr: string): string => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('fr-FR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
    });
  };

  // Navigation vers le détail de la séance
  const navigateToSession = async (session: SessionDetail) => {
    if (!user?.id) return;

    setLoadingSessionId(session.id);

    try {
      // Récupérer l'activité complète via l'API history (même jour)
      const result = await activitiesService.getHistory(
        user.id,
        session.date,
        session.date
      );

      if (result.success && result.activities) {
        // Trouver l'activité correspondante par ID ou nom
        const activity = result.activities.find(
          a => a.id === session.id || a.name === session.name
        );

        if (activity) {
          navigation.navigate('SessionDetail', {
            session: activity,
            isPlanned: false,
          });
        } else {
          // Si pas trouvé, créer un objet Activity minimal
          const minimalActivity: Activity = {
            id: session.id,
            user_id: user.id,
            date: session.date,
            type: 'completed',
            discipline: session.discipline,
            name: session.name,
            title: session.name,
            duration: dashboardService.formatDuration(session.duration),
            distance: dashboardService.formatDistance(session.distance, session.discipline),
            pace: null,
            avgWatt: session.avgPower,
            maxWatt: null,
            rpe: null,
            feeling: null,
            elevationGain: session.elevation,
            elevationLoss: null,
            loadFoster: null,
            loadCoggan: null,
            isCompetition: false,
            kilojoules: session.calories,
            restHr: null,
            maxHr: null,
            normalizedPower: null,
            ftp: null,
            weight: null,
            zones: null,
            fileUrl: null,
            fileData: null,
            plannedName: null,
            plannedSport: null,
            plannedDescription: null,
            description: null,
            notes: null,
            coachInstructions: null,
            scheduledTime: null,
            timeOfDay: null,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          };

          navigation.navigate('SessionDetail', {
            session: minimalActivity,
            isPlanned: false,
          });
        }
      }
    } catch (err) {
      console.error('Erreur navigation vers séance:', err);
    } finally {
      setLoadingSessionId(null);
    }
  };

  // Rendu d'une séance
  const renderSession = ({ item }: { item: SessionDetail }) => {
    const disciplineColor = getDisciplineColor(item.discipline);
    const isLoadingThis = loadingSessionId === item.id;

    return (
      <TouchableOpacity
        style={styles.sessionCard}
        activeOpacity={0.7}
        onPress={() => navigateToSession(item)}
        disabled={loadingSessionId !== null}
      >
        <View style={[styles.sessionIconContainer, { backgroundColor: disciplineColor + '20' }]}>
          <Icon
            name={dashboardService.getDisciplineIcon(item.discipline)}
            size={24}
            color={disciplineColor}
          />
        </View>

        <View style={styles.sessionContent}>
          <Text style={styles.sessionName} numberOfLines={1}>
            {item.name}
          </Text>
          <Text style={styles.sessionDate}>{formatDate(item.date)}</Text>

          <View style={styles.sessionStats}>
            {/* Durée */}
            <View style={styles.statItem}>
              <Icon name="time-outline" size={14} color={colors.neutral.gray[500]} />
              <Text style={styles.statText}>
                {dashboardService.formatDuration(item.duration)}
              </Text>
            </View>

            {/* Distance */}
            {item.distance > 0 && (
              <View style={styles.statItem}>
                <Icon name="navigate-outline" size={14} color={colors.neutral.gray[500]} />
                <Text style={styles.statText}>
                  {dashboardService.formatDistance(item.distance, item.discipline)}
                </Text>
              </View>
            )}

            {/* Calories */}
            {item.calories > 0 && (
              <View style={styles.statItem}>
                <Icon name="flame-outline" size={14} color={colors.neutral.gray[500]} />
                <Text style={styles.statText}>{item.calories} kcal</Text>
              </View>
            )}
          </View>
        </View>

        {isLoadingThis ? (
          <ActivityIndicator size="small" color={colors.primary[500]} />
        ) : (
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        )}
      </TouchableOpacity>
    );
  };

  // État de chargement
  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color={colors.primary[500]} />
        <Text style={styles.loadingText}>Chargement des séances...</Text>
      </View>
    );
  }

  // État d'erreur
  if (error) {
    return (
      <View style={styles.centerContainer}>
        <Icon name="alert-circle-outline" size={48} color={colors.neutral.gray[400]} />
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={loadSessions}>
          <Text style={styles.retryButtonText}>Réessayer</Text>
        </TouchableOpacity>
      </View>
    );
  }

  // Liste vide
  if (sessions.length === 0) {
    return (
      <View style={styles.centerContainer}>
        <Icon
          name={dashboardService.getDisciplineIcon(discipline)}
          size={48}
          color={colors.neutral.gray[300]}
        />
        <Text style={styles.emptyText}>
          Aucune séance de {dashboardService.getDisciplineName(discipline).toLowerCase()} cette semaine
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header avec résumé */}
      <View style={styles.summaryHeader}>
        <Text style={styles.summaryText}>
          {sessions.length} séance{sessions.length > 1 ? 's' : ''} cette semaine
        </Text>
      </View>

      {/* Liste des séances */}
      <FlatList
        data={sessions}
        keyExtractor={(item) => item.id}
        renderItem={renderSession}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing.xl,
    backgroundColor: colors.light.background,
  },
  loadingText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  errorText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
    textAlign: 'center',
  },
  retryButton: {
    marginTop: spacing.lg,
    backgroundColor: colors.primary[500],
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.lg,
    borderRadius: spacing.borderRadius.md,
  },
  retryButtonText: {
    ...typography.styles.buttonSmall,
    color: colors.neutral.white,
  },
  emptyText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
    textAlign: 'center',
  },
  summaryHeader: {
    paddingHorizontal: spacing.container.horizontal,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
    backgroundColor: colors.neutral.white,
  },
  summaryText: {
    ...typography.styles.label,
    color: colors.neutral.gray[600],
  },
  listContent: {
    padding: spacing.container.horizontal,
    paddingTop: spacing.md,
  },
  sessionCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    marginBottom: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  sessionIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  sessionContent: {
    flex: 1,
  },
  sessionName: {
    ...typography.styles.label,
    color: colors.secondary[800],
    marginBottom: 2,
  },
  sessionDate: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginBottom: spacing.xs,
    textTransform: 'capitalize',
  },
  sessionStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  statText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
  },
});

export default DisciplineSessionsScreen;
