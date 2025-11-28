/**
 * Types de navigation pour EdgeCoach iOS
 */

import { NavigatorScreenParams } from '@react-navigation/native';

// Stack Auth (non connecté)
export type AuthStackParamList = {
  Login: undefined;
  Register: undefined;
};

// Tab Bar (connecté)
export type MainTabParamList = {
  Dashboard: undefined;
  CoachChat: undefined;
  Calendar: undefined;
  Stats: undefined;
  Profile: undefined;
};

// Import des types de session
import { Activity } from '../services/activitiesService';
import { PlannedSession } from '../services/plansService';
import { DisciplineType, WeeklySummaryData } from '../services/dashboardService';

// Stack principale avec nested navigators
export type RootStackParamList = {
  Auth: NavigatorScreenParams<AuthStackParamList>;
  Main: NavigatorScreenParams<MainTabParamList>;
  // Écrans modaux ou détails
  Settings: undefined;
  TrainingPlanCreator: undefined;
  TrainingPlanDetail: { planId: string };
  WorkoutDetail: { workoutId: string };
  SessionDetail: { session: Activity | PlannedSession; isPlanned: boolean };
  DisciplineSessions: { discipline: DisciplineType; weekStart?: string };
  WeeklyProgressDetail: { weeklyData: WeeklySummaryData | null };
  Zones: undefined;
  Equipment: undefined;
  EditProfile: undefined;
};

// Déclaration pour la navigation typée
declare global {
  namespace ReactNavigation {
    interface RootParamList extends RootStackParamList {}
  }
}
