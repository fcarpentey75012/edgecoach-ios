/**
 * Service de gestion du coach sélectionné
 * Gère la persistance et la synchronisation avec le backend
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  Coach,
  Sport,
  getCoachById,
  getDefaultCoach,
  defaultCoachSelection,
} from '../data/coaches';
import apiService from './api';

const STORAGE_KEY = 'selectedCoach';

export interface SelectedCoach extends Coach {
  sport: Sport;
}

export interface CoachSelection {
  sport: Sport;
  coachId: string;
}

class CoachService {
  private currentCoach: SelectedCoach | null = null;
  private listeners: ((coach: SelectedCoach) => void)[] = [];

  /**
   * Initialise le service et charge le coach sauvegardé
   */
  async initialize(): Promise<SelectedCoach> {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEY);
      if (stored) {
        const selection: CoachSelection = JSON.parse(stored);
        const coach = getCoachById(selection.sport, selection.coachId);
        if (coach) {
          this.currentCoach = { ...coach, sport: selection.sport };
          return this.currentCoach;
        }
      }
    } catch (error) {
      console.error('Error loading coach selection:', error);
    }

    // Par défaut, retourne Jan (Triathlon)
    this.currentCoach = getDefaultCoach();
    return this.currentCoach;
  }

  /**
   * Récupère le coach actuellement sélectionné
   */
  getCurrentCoach(): SelectedCoach {
    if (!this.currentCoach) {
      this.currentCoach = getDefaultCoach();
    }
    return this.currentCoach;
  }

  /**
   * Sélectionne un nouveau coach
   */
  async selectCoach(sport: Sport, coachId: string, userId?: string): Promise<boolean> {
    const coach = getCoachById(sport, coachId);
    if (!coach) {
      console.error('Coach not found:', sport, coachId);
      return false;
    }

    const selectedCoach: SelectedCoach = { ...coach, sport };
    this.currentCoach = selectedCoach;

    // Sauvegarder localement
    const selection: CoachSelection = { sport, coachId };
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(selection));
    } catch (error) {
      console.error('Error saving coach selection:', error);
    }

    // Synchroniser avec le backend si userId disponible
    if (userId) {
      try {
        await this.syncWithBackend(userId, selectedCoach);
      } catch (error) {
        console.error('Error syncing coach with backend:', error);
      }
    }

    // Notifier les listeners
    this.notifyListeners(selectedCoach);

    return true;
  }

  /**
   * Synchronise la sélection avec le backend
   */
  private async syncWithBackend(userId: string, coach: SelectedCoach): Promise<void> {
    await apiService.post(`/coach/selection?user_id=${userId}`, {
      coach_id: coach.id,
      name: coach.name,
      sport: coach.sport,
      speciality: coach.speciality,
      description: coach.description,
      avatar: coach.avatar,
      experience: coach.experience,
      expertise: coach.expertise,
    });
  }

  /**
   * Ajoute un listener pour les changements de coach
   */
  addListener(callback: (coach: SelectedCoach) => void): () => void {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  /**
   * Notifie tous les listeners d'un changement
   */
  private notifyListeners(coach: SelectedCoach): void {
    this.listeners.forEach(listener => listener(coach));
  }
}

export const coachService = new CoachService();
export default coachService;
