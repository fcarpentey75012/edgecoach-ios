/**
 * Écran Calendrier - Planning d'entraînement
 * Affiche les séances prévues et effectuées
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation, CompositeNavigationProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { useAuth } from '../contexts/AuthContext';
import { activitiesService, Activity } from '../services/activitiesService';
import { plansService, PlannedSession } from '../services/plansService';
import { RootStackParamList, MainTabParamList } from '../navigation/types';
import { WeekSummary, MultiSessionSummary } from '../components/calendar';
import { ZonesChartCompact } from '../components/session';
import { colors, spacing, typography } from '../theme';

// Type composite pour naviguer depuis un Tab vers un écran du Stack parent
type CalendarNavigationProp = CompositeNavigationProp<
  BottomTabNavigationProp<MainTabParamList, 'Calendar'>,
  NativeStackNavigationProp<RootStackParamList>
>;

// Types
type ViewMode = 'completed' | 'planned';
type CalendarViewType = 'month' | 'week';

interface CalendarDay {
  date: Date;
  isCurrentMonth: boolean;
  isToday: boolean;
  completedSessions: Activity[];
  plannedSessions: PlannedSession[];
}

// Jours de la semaine
const WEEK_DAYS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

// Noms des mois
const MONTH_NAMES = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
];

// Helper pour obtenir le début et la fin de la semaine
const getWeekBounds = (date: Date): { start: Date; end: Date } => {
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1); // Ajuster pour commencer lundi
  const start = new Date(date);
  start.setDate(diff);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(start.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return { start, end };
};

// Helper pour calculer le TSS total d'une séance (indicateur d'intensité)
const getSessionIntensityColor = (session: Activity): string => {
  const tss = session.loadCoggan;
  if (!tss) return colors.neutral.gray[300];
  if (tss < 50) return colors.status.success; // Récupération
  if (tss < 100) return '#84cc16'; // Endurance
  if (tss < 150) return colors.status.warning; // Tempo/Seuil
  return colors.status.error; // Haute intensité
};

const CalendarScreen: React.FC = () => {
  const navigation = useNavigation<CalendarNavigationProp>();
  const { user } = useAuth();
  const [currentDate, setCurrentDate] = useState(new Date());
  const [viewMode, setViewMode] = useState<ViewMode>('completed');
  const [calendarViewType, setCalendarViewType] = useState<CalendarViewType>('month');
  const [completedSessions, setCompletedSessions] = useState<Activity[]>([]);
  const [plannedSessions, setPlannedSessions] = useState<PlannedSession[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedDay, setSelectedDay] = useState<CalendarDay | null>(null);
  const [todayInitialized, setTodayInitialized] = useState(false);

  // Naviguer vers le détail d'une séance
  const navigateToSessionDetail = (session: Activity | PlannedSession, isPlanned: boolean) => {
    navigation.navigate('SessionDetail', { session, isPlanned });
  };

  // Charger les données du mois
  const loadMonthData = useCallback(async (forceRefresh = false) => {
    if (!user?.id) return;

    if (forceRefresh) {
      setIsRefreshing(true);
    } else {
      setIsLoading(true);
    }

    try {
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth();

      // Charger les séances effectuées et prévues en parallèle
      const [activitiesResult, plansResult] = await Promise.all([
        activitiesService.getMonthActivities(user.id, year, month),
        plansService.getLastPlan(user.id),
      ]);

      if (activitiesResult.success && activitiesResult.activities) {
        setCompletedSessions(activitiesResult.activities);
      }

      if (plansResult.success && plansResult.sessions) {
        // Filtrer les sessions pour le mois courant
        const monthSessions = plansService.filterByMonth(plansResult.sessions, year, month);
        setPlannedSessions(monthSessions);
      }
    } catch (error) {
      console.error('Error loading calendar data:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [currentDate, user?.id]);

  useEffect(() => {
    loadMonthData();
  }, [loadMonthData]);

  // Sélectionner aujourd'hui par défaut après le chargement initial
  useEffect(() => {
    if (!isLoading && !todayInitialized && completedSessions.length >= 0) {
      const today = new Date();
      const todayStr = today.toISOString().split('T')[0];
      const completedByDate = activitiesService.groupByDate(completedSessions);
      const plannedByDate = plansService.groupByDate(plannedSessions);

      setSelectedDay({
        date: today,
        isCurrentMonth: true,
        isToday: true,
        completedSessions: completedByDate[todayStr] || [],
        plannedSessions: plannedByDate[todayStr] || [],
      });
      setTodayInitialized(true);
    }
  }, [isLoading, todayInitialized, completedSessions, plannedSessions]);

  // Navigation entre les mois
  const goToPreviousMonth = () => {
    setCurrentDate(prev => new Date(prev.getFullYear(), prev.getMonth() - 1, 1));
    setSelectedDay(null);
  };

  const goToNextMonth = () => {
    setCurrentDate(prev => new Date(prev.getFullYear(), prev.getMonth() + 1, 1));
    setSelectedDay(null);
  };

  const goToToday = () => {
    setCurrentDate(new Date());
    setSelectedDay(null);
  };

  // Générer les jours du calendrier
  const generateCalendarDays = (): CalendarDay[] => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();

    // Premier jour du mois
    const firstDay = new Date(year, month, 1);
    // Dernier jour du mois
    const lastDay = new Date(year, month + 1, 0);

    // Jour de la semaine du premier jour (0 = dimanche, 1 = lundi, etc.)
    let startDay = firstDay.getDay();
    // Convertir pour commencer par lundi (0 = lundi)
    startDay = startDay === 0 ? 6 : startDay - 1;

    // Grouper les sessions par date
    const completedByDate = activitiesService.groupByDate(completedSessions);
    const plannedByDate = plansService.groupByDate(plannedSessions);

    const days: CalendarDay[] = [];
    const today = new Date();

    // Jours du mois précédent
    const prevMonthLastDay = new Date(year, month, 0).getDate();
    for (let i = startDay - 1; i >= 0; i--) {
      const date = new Date(year, month - 1, prevMonthLastDay - i);
      const dateStr = date.toISOString().split('T')[0];
      days.push({
        date,
        isCurrentMonth: false,
        isToday: false,
        completedSessions: completedByDate[dateStr] || [],
        plannedSessions: plannedByDate[dateStr] || [],
      });
    }

    // Jours du mois courant
    for (let day = 1; day <= lastDay.getDate(); day++) {
      const date = new Date(year, month, day);
      const dateStr = date.toISOString().split('T')[0];
      days.push({
        date,
        isCurrentMonth: true,
        isToday: date.toDateString() === today.toDateString(),
        completedSessions: completedByDate[dateStr] || [],
        plannedSessions: plannedByDate[dateStr] || [],
      });
    }

    // Jours du mois suivant pour compléter la grille
    const remainingDays = 42 - days.length; // 6 semaines x 7 jours
    for (let day = 1; day <= remainingDays; day++) {
      const date = new Date(year, month + 1, day);
      const dateStr = date.toISOString().split('T')[0];
      days.push({
        date,
        isCurrentMonth: false,
        isToday: false,
        completedSessions: completedByDate[dateStr] || [],
        plannedSessions: plannedByDate[dateStr] || [],
      });
    }

    return days;
  };

  // Obtenir la couleur de la discipline
  const getDisciplineColor = (discipline: string): string => {
    switch (discipline) {
      case 'cyclisme':
        return colors.sports.cycling;
      case 'course':
        return colors.sports.running;
      case 'natation':
        return colors.sports.swimming;
      default:
        return colors.neutral.gray[400];
    }
  };

  // Rendu d'un indicateur de session amélioré avec intensité
  const renderSessionIndicator = (session: Activity | PlannedSession, isPlanned: boolean, index: number) => {
    const disciplineColor = getDisciplineColor(session.discipline);

    if (isPlanned) {
      // Séance prévue : bordure pointillée
      return (
        <View
          key={`${session.id}-${index}`}
          style={[
            styles.sessionDot,
            styles.sessionDotPlanned,
            { borderColor: disciplineColor },
          ]}
        />
      );
    }

    // Séance effectuée : point avec indicateur d'intensité
    const activity = session as Activity;
    const intensityColor = getSessionIntensityColor(activity);
    const hasTSS = activity.loadCoggan && activity.loadCoggan > 0;

    return (
      <View key={`${session.id}-${index}`} style={styles.sessionIndicatorWrapper}>
        <View
          style={[
            styles.sessionDot,
            { backgroundColor: disciplineColor },
          ]}
        />
        {hasTSS && (
          <View
            style={[
              styles.intensityRing,
              { borderColor: intensityColor },
            ]}
          />
        )}
      </View>
    );
  };

  // Calculer les sessions de la semaine courante
  const getWeekSessions = () => {
    const { start, end } = getWeekBounds(currentDate);
    const weekCompleted = completedSessions.filter(s => {
      const sessionDate = new Date(s.date);
      return sessionDate >= start && sessionDate <= end;
    });
    const weekPlanned = plannedSessions.filter(s => {
      const sessionDate = new Date(s.date);
      return sessionDate >= start && sessionDate <= end;
    });
    return { weekCompleted, weekPlanned, start, end };
  };

  // Rendu d'un jour du calendrier
  const renderDay = (day: CalendarDay, index: number) => {
    const sessions = viewMode === 'completed' ? day.completedSessions : day.plannedSessions;
    const isSelected = selectedDay?.date.toDateString() === day.date.toDateString();

    return (
      <TouchableOpacity
        key={index}
        style={[
          styles.dayCell,
          !day.isCurrentMonth && styles.dayCellOtherMonth,
          day.isToday && styles.dayCellToday,
          isSelected && styles.dayCellSelected,
        ]}
        onPress={() => setSelectedDay(day)}
      >
        <Text
          style={[
            styles.dayNumber,
            !day.isCurrentMonth && styles.dayNumberOtherMonth,
            day.isToday && styles.dayNumberToday,
            isSelected && styles.dayNumberSelected,
          ]}
        >
          {day.date.getDate()}
        </Text>
        <View style={styles.sessionIndicators}>
          {sessions.slice(0, 3).map((session, i) =>
            renderSessionIndicator(session, viewMode === 'planned', i)
          )}
          {sessions.length > 3 && (
            <Text style={styles.moreIndicator}>+{sessions.length - 3}</Text>
          )}
        </View>
      </TouchableOpacity>
    );
  };

  // Rendu du détail d'une séance
  const renderSessionDetail = (session: Activity | PlannedSession, isPlanned: boolean) => {
    const color = getDisciplineColor(session.discipline);
    const duration = isPlanned
      ? (session as PlannedSession).estimatedDuration
      : (session as Activity).duration;
    const distance = isPlanned
      ? (session as PlannedSession).estimatedDistance
      : (session as Activity).distance;

    return (
      <TouchableOpacity
        key={session.id}
        style={styles.sessionCard}
        onPress={() => navigateToSessionDetail(session, isPlanned)}
        activeOpacity={0.7}
      >
        <View style={[styles.sessionColorBar, { backgroundColor: color }]} />
        <View style={styles.sessionContent}>
          <View style={styles.sessionHeader}>
            <Text style={styles.sessionTitle}>{session.title}</Text>
            <View style={styles.sessionHeaderRight}>
              {isPlanned && (
                <View style={styles.plannedBadge}>
                  <Text style={styles.plannedBadgeText}>Prévu</Text>
                </View>
              )}
              <Icon name="chevron-forward" size={16} color={colors.neutral.gray[400]} />
            </View>
          </View>
          <View style={styles.sessionMeta}>
            {duration && (
              <View style={styles.sessionMetaItem}>
                <Icon name="time-outline" size={14} color={colors.neutral.gray[500]} />
                <Text style={styles.sessionMetaText}>{duration}</Text>
              </View>
            )}
            {distance && (
              <View style={styles.sessionMetaItem}>
                <Icon name="map-outline" size={14} color={colors.neutral.gray[500]} />
                <Text style={styles.sessionMetaText}>{distance}</Text>
              </View>
            )}
          </View>
          {session.description && (
            <Text style={styles.sessionDescription} numberOfLines={2}>
              {session.description}
            </Text>
          )}
        </View>
      </TouchableOpacity>
    );
  };

  const calendarDays = generateCalendarDays();

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary[500]} />
        <Text style={styles.loadingText}>Chargement du calendrier...</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl
          refreshing={isRefreshing}
          onRefresh={() => loadMonthData(true)}
          colors={[colors.primary[500]]}
        />
      }
    >
      {/* Header de navigation */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.navButton} onPress={goToPreviousMonth}>
          <Icon name="chevron-back" size={24} color={colors.secondary[800]} />
        </TouchableOpacity>
        <TouchableOpacity onPress={goToToday}>
          <Text style={styles.monthTitle}>
            {MONTH_NAMES[currentDate.getMonth()]} {currentDate.getFullYear()}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.navButton} onPress={goToNextMonth}>
          <Icon name="chevron-forward" size={24} color={colors.secondary[800]} />
        </TouchableOpacity>
      </View>

      {/* Toggle Vue Mois/Semaine */}
      <View style={styles.calendarViewToggle}>
        <TouchableOpacity
          style={[styles.calendarViewButton, calendarViewType === 'month' && styles.calendarViewButtonActive]}
          onPress={() => setCalendarViewType('month')}
        >
          <Icon name="calendar" size={16} color={calendarViewType === 'month' ? colors.primary[600] : colors.neutral.gray[500]} />
          <Text style={[styles.calendarViewText, calendarViewType === 'month' && styles.calendarViewTextActive]}>Mois</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.calendarViewButton, calendarViewType === 'week' && styles.calendarViewButtonActive]}
          onPress={() => setCalendarViewType('week')}
        >
          <Icon name="stats-chart" size={16} color={calendarViewType === 'week' ? colors.primary[600] : colors.neutral.gray[500]} />
          <Text style={[styles.calendarViewText, calendarViewType === 'week' && styles.calendarViewTextActive]}>Semaine</Text>
        </TouchableOpacity>
      </View>

      {/* Toggle Vue Effectuées/Prévues + Légende compacte */}
      <View style={styles.toggleAndLegendRow}>
        <View style={styles.viewToggle}>
          <TouchableOpacity
            style={[styles.toggleButton, viewMode === 'completed' && styles.toggleButtonActive]}
            onPress={() => setViewMode('completed')}
          >
            <Text style={[styles.toggleText, viewMode === 'completed' && styles.toggleTextActive]}>
              Effectuées
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.toggleButton, viewMode === 'planned' && styles.toggleButtonActive]}
            onPress={() => setViewMode('planned')}
          >
            <Text style={[styles.toggleText, viewMode === 'planned' && styles.toggleTextActive]}>
              Prévues
            </Text>
          </TouchableOpacity>
        </View>
        <View style={styles.legendInline}>
          <View style={[styles.legendDotSmall, { backgroundColor: colors.sports.cycling }]} />
          <View style={[styles.legendDotSmall, { backgroundColor: colors.sports.running }]} />
          <View style={[styles.legendDotSmall, { backgroundColor: colors.sports.swimming }]} />
        </View>
      </View>

      {/* Résumé hebdomadaire (visible en mode semaine) */}
      {calendarViewType === 'week' && (() => {
        const { weekCompleted, weekPlanned, start, end } = getWeekSessions();
        return (
          <WeekSummary
            completedSessions={weekCompleted}
            plannedSessions={weekPlanned}
            weekStart={start}
            weekEnd={end}
          />
        );
      })()}

      {/* En-têtes des jours */}
      <View style={styles.weekHeader}>
        {WEEK_DAYS.map(day => (
          <Text key={day} style={styles.weekDay}>
            {day}
          </Text>
        ))}
      </View>

      {/* Grille du calendrier */}
      <View style={styles.calendarGrid}>
        {calendarDays.map((day, index) => renderDay(day, index))}
      </View>

      {/* Détail du jour sélectionné */}
      {selectedDay && (
        <View style={styles.selectedDaySection}>
          <Text style={styles.selectedDayTitle}>
            {selectedDay.date.toLocaleDateString('fr-FR', {
              weekday: 'long',
              day: 'numeric',
              month: 'long',
            })}
          </Text>

          {viewMode === 'completed' ? (
            selectedDay.completedSessions.length > 0 ? (
              <>
                {/* Widget multi-séances si 2+ séances */}
                {selectedDay.completedSessions.length >= 2 && (
                  <MultiSessionSummary
                    sessions={selectedDay.completedSessions}
                    date={selectedDay.date}
                  />
                )}
                {/* Liste des séances individuelles */}
                {selectedDay.completedSessions.map(session =>
                  renderSessionDetail(session, false)
                )}
              </>
            ) : (
              <View style={styles.emptyDay}>
                <Icon name="fitness-outline" size={32} color={colors.neutral.gray[300]} />
                <Text style={styles.emptyDayText}>Aucune séance effectuée ce jour</Text>
              </View>
            )
          ) : selectedDay.plannedSessions.length > 0 ? (
            selectedDay.plannedSessions.map(session =>
              renderSessionDetail(session, true)
            )
          ) : (
            <View style={styles.emptyDay}>
              <Icon name="calendar-outline" size={32} color={colors.neutral.gray[300]} />
              <Text style={styles.emptyDayText}>Aucune séance prévue ce jour</Text>
            </View>
          )}
        </View>
      )}

    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  content: {
    padding: spacing.sm,
    paddingBottom: spacing.xl,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.light.background,
  },
  loadingText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  calendarViewToggle: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.xs,
    marginBottom: spacing.xs,
  },
  calendarViewButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.xs,
    borderRadius: spacing.borderRadius.md,
    gap: spacing.xs,
  },
  calendarViewButtonActive: {
    backgroundColor: colors.primary[50],
  },
  calendarViewText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontWeight: '500',
  },
  calendarViewTextActive: {
    color: colors.primary[600],
    fontWeight: '600',
  },
  navButton: {
    padding: spacing.sm,
    borderRadius: spacing.borderRadius.md,
    backgroundColor: colors.neutral.white,
  },
  monthTitle: {
    ...typography.styles.h3,
    color: colors.secondary[800],
    textTransform: 'capitalize',
  },
  toggleAndLegendRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  viewToggle: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.xs,
    flex: 1,
    marginRight: spacing.sm,
  },
  toggleButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.xs,
    borderRadius: spacing.borderRadius.md,
  },
  toggleButtonActive: {
    backgroundColor: colors.primary[50],
  },
  toggleText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontWeight: '500',
  },
  toggleTextActive: {
    color: colors.primary[600],
    fontWeight: '600',
  },
  legendInline: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.neutral.white,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: spacing.borderRadius.md,
  },
  legendDotSmall: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  weekHeader: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    paddingVertical: spacing.sm,
    marginBottom: spacing.xs,
  },
  weekDay: {
    flex: 1,
    textAlign: 'center',
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontWeight: '600',
  },
  calendarGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    overflow: 'hidden',
  },
  dayCell: {
    width: '14.28%',
    height: 44,
    paddingVertical: spacing.xs,
    paddingHorizontal: 2,
    borderWidth: 0.5,
    borderColor: colors.neutral.gray[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
  dayCellOtherMonth: {
    backgroundColor: colors.neutral.gray[50],
  },
  dayCellToday: {
    backgroundColor: colors.primary[50],
  },
  dayCellSelected: {
    backgroundColor: colors.primary[100],
    borderColor: colors.primary[500],
    borderWidth: 1,
  },
  dayNumber: {
    ...typography.styles.caption,
    color: colors.secondary[800],
    fontWeight: '500',
  },
  dayNumberOtherMonth: {
    color: colors.neutral.gray[400],
  },
  dayNumberToday: {
    color: colors.primary[600],
    fontWeight: '700',
  },
  dayNumberSelected: {
    color: colors.primary[700],
    fontWeight: '700',
  },
  sessionIndicators: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 2,
    marginTop: 2,
  },
  sessionIndicatorWrapper: {
    position: 'relative',
    width: 10,
    height: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sessionDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  sessionDotPlanned: {
    borderWidth: 1.5,
    backgroundColor: 'transparent',
  },
  intensityRing: {
    position: 'absolute',
    width: 10,
    height: 10,
    borderRadius: 5,
    borderWidth: 1.5,
  },
  moreIndicator: {
    ...typography.styles.caption,
    fontSize: 8,
    color: colors.neutral.gray[500],
  },
  selectedDaySection: {
    marginTop: spacing.sm,
  },
  selectedDayTitle: {
    ...typography.styles.h4,
    color: colors.secondary[800],
    textTransform: 'capitalize',
    marginBottom: spacing.md,
  },
  sessionCard: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    marginBottom: spacing.sm,
    overflow: 'hidden',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 1,
  },
  sessionColorBar: {
    width: 4,
  },
  sessionContent: {
    flex: 1,
    padding: spacing.md,
  },
  sessionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  sessionTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
    flex: 1,
  },
  sessionHeaderRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  plannedBadge: {
    backgroundColor: colors.primary[100],
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: spacing.borderRadius.sm,
  },
  plannedBadgeText: {
    ...typography.styles.caption,
    color: colors.primary[700],
    fontWeight: '600',
  },
  sessionMeta: {
    flexDirection: 'row',
    gap: spacing.md,
    marginBottom: spacing.xs,
  },
  sessionMetaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  sessionMetaText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
  },
  sessionDescription: {
    ...typography.styles.bodySmall,
    color: colors.neutral.gray[500],
  },
  emptyDay: {
    alignItems: 'center',
    padding: spacing.xl,
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
  },
  emptyDayText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
    marginTop: spacing.sm,
  },
});

export default CalendarScreen;
