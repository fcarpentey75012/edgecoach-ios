/**
 * Export centralisé des services
 */

// Services
export { apiService, default as api } from './api';
export { userService, default as user } from './userService';
export { chatService, default as chat } from './chatService';
export { conversationService, default as conversation } from './conversationService';
export { metricsService, default as metrics } from './metricsService';
export { userMetricsService, default as userMetrics } from './userMetricsService';
export { equipmentService, default as equipment } from './equipmentService';
export { wahooService, default as wahoo } from './wahooService';

// Types - User Service
export type { User, RegisterData, LoginCredentials, ApiResponse } from './userService';

// Types - Chat Service
export type { ChatMessage, SendMessageOptions } from './chatService';

// Types - Conversation Service
export type {
  Message,
  Conversation,
  ConversationListItem,
  ConversationStats,
} from './conversationService';

// Types - Metrics Service
export type {
  HeartRateZone,
  PowerZone,
  PaceZone,
  RunningZones,
  CyclingZones,
  SwimmingZones,
  SportsZones,
  UserMetrics,
  MetricsResult,
} from './metricsService';

// Types - User Metrics Service
export type {
  UserMetricsData,
  UserMetricsResult,
  MetricsSummary,
  MetricsSummaryResult,
} from './userMetricsService';

// Types - Equipment Service
export type {
  EquipmentItem,
  SportEquipment,
  UserEquipment,
  AddEquipmentData,
  UpdateEquipmentData,
  EquipmentResult,
  EquipmentItemResult,
} from './equipmentService';

// Types - Wahoo Service
export type {
  WahooTokens,
  WahooProfile,
  WahooWorkout,
  WahooConnectionStatus,
  WahooAuthResult,
  WahooExchangeResult,
} from './wahooService';

// Services - Activities & Plans
export { activitiesService, default as activities } from './activitiesService';
export { plansService, default as plans } from './plansService';
export { logbookService, default as logbook } from './logbookService';
export { dashboardService, default as dashboard } from './dashboardService';
export { statsService, default as stats } from './statsService';
export { statsAdvancedService, default as statsAdvanced } from './statsAdvancedService';

// Types - Activities Service
export type {
  Activity,
  ActivityZone,
  ActivityFileData,
  ActivitiesResult,
} from './activitiesService';

// Types - Plans Service
export type {
  PlannedActivity,
  TrainingPlanData,
  PlannedSession,
  PlansResult,
} from './plansService';

// Types - Logbook Service
export type {
  NutritionItem,
  NutritionTotals,
  NutritionData,
  HydrationItem,
  HydrationData,
  WeatherData,
  SessionEquipment,
  LogbookData,
  SaveLogbookRequest,
  LogbookDocument,
  LogbookResult,
  LogbookListResult,
  SaveLogbookResult,
} from './logbookService';

// Types - Dashboard Service
export type {
  WeeklySummary,
  DisciplineStats,
  ByDiscipline,
  DisciplineType,
  SessionDetail,
  SessionsByDisciplineData,
  SessionsByDisciplineResult,
  UpcomingSession,
  WeekProgress,
  WeeklySummaryData,
  WeeklySummaryResult,
} from './dashboardService';

// Types - Stats Service
export type {
  StatsPeriod,
  StatsSummary,
  DisciplineStats as StatsDisciplineStats,
  ByDisciplineStats,
  PerformanceMetrics,
  EvolutionPoint,
  StatsData,
  StatsResult,
} from './statsService';

// Types - Stats Advanced Service
export type {
  TrainingLoad,
  TrainingLoadStatus,
  TrainingLoadSimple,
  TrainingIntensityZones,
  PDCData,
  SessionInsight,
  RadarScores,
  WeeklyAggregation,
  DecisionRule,
  TrendsData,
  ProfileSnapshot,
  AdvancedStatsData,
  AdvancedStatsResult,
  TrainingLoadResult,
} from './statsAdvancedService';
