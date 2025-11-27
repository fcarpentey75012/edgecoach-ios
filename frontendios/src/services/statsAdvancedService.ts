/**
 * Service Stats Avancées pour EdgeCoach iOS
 * Métriques niveau Wahoo/Garmin: CTL/ATL/TSB, PDC, Radar, Sessions détaillées
 */

import apiService from './api';

// ============ TYPES ============

// Training Load (Charge d'entraînement)
export interface TrainingLoad {
  ctl: number | null; // Chronic Training Load (Fitness)
  atl: number | null; // Acute Training Load (Fatigue)
  tsb: number | null; // Training Stress Balance (Form)
  last7dTss: number | null;
  last42dTss: number | null;
  monotony: number | null;
  daysCovered: number;
}

export type TrainingLoadStatus = 'fresh' | 'ready' | 'neutral' | 'tired' | 'overreached' | 'unknown';

export interface TrainingLoadSimple extends TrainingLoad {
  status: TrainingLoadStatus;
  statusLabel: string;
}

// Training Intensity Zones
export interface TrainingIntensityZones {
  Z1_Z2: number; // 0-1 (aérobie base)
  Z3: number; // 0-1 (tempo)
  Z4_Z5: number; // 0-1 (seuil/VO2max)
}

// Power Duration Curve
export interface PDCData {
  '5': number | null; // 5 secondes
  '60': number | null; // 1 minute
  '300': number | null; // 5 minutes
  '1200': number | null; // 20 minutes
  '3600': number | null; // 60 minutes
}

// Session Insight (analyse d'une séance)
export interface SessionInsight {
  sessionId: string;
  sport: 'running' | 'cycling' | 'swimming';
  date: string;
  durationMin: number | null;
  distanceKm: number | null;
  tiz: TrainingIntensityZones;
  cvActive: number | null;
  // Course à pied
  paHr: number | null; // Dérive Pa:Hr %
  // Cyclisme
  np: number | null; // Normalized Power
  intensityFactor: number | null; // IF
  tss: number | null; // Training Stress Score
  pwHr: number | null; // Dérive Pw:Hr %
  pdc: PDCData | null;
  // Natation
  density: number | null;
}

// Radar Scores (0-100)
export interface RadarScores {
  aerobicEndurance: number;
  thresholdDurability: number;
  vo2Hi: number;
  techniqueEconomy: number;
  consistencyLoad: number;
  overall: number;
}

// Weekly Aggregation
export interface WeeklyAggregation {
  year: number;
  week: number;
  sessionsCount: number;
  volumeMin: number;
  distanceKm: number;
  intensityDistribution: TrainingIntensityZones;
}

// Decision Rule (Alerte/Recommandation)
export interface DecisionRule {
  ruleId: string;
  label: string;
  severity: 'info' | 'warning' | 'critical';
  evidence: Record<string, any>;
}

// Trends
export interface TrendsData {
  bikePdc20minSlope: number | null;
  bikePdc60minSlope: number | null;
}

// Profile Snapshot
export interface ProfileSnapshot {
  hrMax: number | null;
  weightKg: number | null;
  cyclingCp: number | null; // Critical Power
  cyclingFtp: number | null;
  runningCsMs: number | null; // Critical Speed m/s
  runningVma: number | null;
  swimmingCss: number | null; // s/100m
}

// Réponse complète Advanced Stats
export interface AdvancedStatsData {
  load: TrainingLoad;
  sessions: SessionInsight[];
  weekly: Record<string, WeeklyAggregation>;
  weeklyBySport: Record<string, any>;
  trends: TrendsData;
  decisions: DecisionRule[];
  radar: RadarScores;
  profile: ProfileSnapshot;
  meta: {
    computedAt: string;
    daysAnalyzed: number;
    sportsAnalyzed: string[];
  };
}

// ============ API RESPONSE TYPES ============

interface ApiAdvancedStatsResponse {
  status: string;
  data: {
    load: {
      ctl: number | null;
      atl: number | null;
      tsb: number | null;
      last_7d_tss: number | null;
      last_42d_tss: number | null;
      monotony: number | null;
      days_covered: number;
    };
    sessions: Array<{
      session_id: string;
      sport: string;
      date: string;
      duration_min: number | null;
      distance_km: number | null;
      tiz: { Z1_Z2: number; Z3: number; Z4_Z5: number };
      cv_active: number | null;
      pa_hr: number | null;
      np: number | null;
      intensity_factor: number | null;
      if?: number | null;
      tss: number | null;
      pw_hr: number | null;
      pdc: PDCData | null;
      density: number | null;
    }>;
    weekly: Record<string, any>;
    weekly_by_sport: Record<string, any>;
    trends: {
      bike_pdc_20min_slope: number | null;
      bike_pdc_60min_slope: number | null;
    };
    decisions: Array<{
      rule_id: string;
      label: string;
      severity: string;
      evidence: Record<string, any>;
    }>;
    radar: {
      aerobic_endurance: number;
      threshold_durability: number;
      vo2_hi: number;
      technique_economy: number;
      consistency_load: number;
      overall: number;
    };
    profile: {
      hr_max: number | null;
      weight_kg: number | null;
      cycling_cp: number | null;
      cycling_ftp: number | null;
      running_cs_ms: number | null;
      running_vma: number | null;
      swimming_css: number | null;
    };
    meta: {
      computed_at: string;
      days_analyzed: number;
      sports_analyzed: string[];
    };
  };
}

interface ApiTrainingLoadResponse {
  status: string;
  data: {
    ctl: number | null;
    atl: number | null;
    tsb: number | null;
    last_7d_tss: number | null;
    last_42d_tss: number | null;
    days_covered: number;
    status: TrainingLoadStatus;
    status_label: string;
  };
}

// ============ RESULTS ============

export interface AdvancedStatsResult {
  success: boolean;
  data?: AdvancedStatsData;
  error?: string;
}

export interface TrainingLoadResult {
  success: boolean;
  data?: TrainingLoadSimple;
  error?: string;
}

// ============ SERVICE ============

class StatsAdvancedService {
  /**
   * Récupérer les analytics avancées complètes
   */
  async getAdvancedStats(
    userId: string,
    days: number = 90,
    sports: string = 'all'
  ): Promise<AdvancedStatsResult> {
    try {
      const response = await apiService.get<ApiAdvancedStatsResponse>('/stats/advanced', {
        user_id: userId,
        days: days.toString(),
        sports,
      });

      const data = this.convertAdvancedStats(response.data);

      return {
        success: true,
        data,
      };
    } catch (error: any) {
      console.error('Erreur getAdvancedStats:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de la récupération des analytics avancées',
      };
    }
  }

  /**
   * Récupérer uniquement le training load (léger)
   */
  async getTrainingLoad(userId: string, days: number = 90): Promise<TrainingLoadResult> {
    try {
      const response = await apiService.get<ApiTrainingLoadResponse>('/stats/training-load', {
        user_id: userId,
        days: days.toString(),
      });

      const apiData = response.data;
      const data: TrainingLoadSimple = {
        ctl: apiData.ctl,
        atl: apiData.atl,
        tsb: apiData.tsb,
        last7dTss: apiData.last_7d_tss,
        last42dTss: apiData.last_42d_tss,
        monotony: null,
        daysCovered: apiData.days_covered,
        status: apiData.status,
        statusLabel: apiData.status_label,
      };

      return {
        success: true,
        data,
      };
    } catch (error: any) {
      console.error('Erreur getTrainingLoad:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de la récupération du training load',
      };
    }
  }

  /**
   * Convertir la réponse API vers le format frontend (camelCase)
   */
  private convertAdvancedStats(apiData: ApiAdvancedStatsResponse['data']): AdvancedStatsData {
    return {
      load: {
        ctl: apiData.load.ctl,
        atl: apiData.load.atl,
        tsb: apiData.load.tsb,
        last7dTss: apiData.load.last_7d_tss,
        last42dTss: apiData.load.last_42d_tss,
        monotony: apiData.load.monotony,
        daysCovered: apiData.load.days_covered,
      },
      sessions: (apiData.sessions || []).map(s => ({
        sessionId: s.session_id,
        sport: s.sport as 'running' | 'cycling' | 'swimming',
        date: s.date,
        durationMin: s.duration_min,
        distanceKm: s.distance_km,
        tiz: s.tiz,
        cvActive: s.cv_active,
        paHr: s.pa_hr,
        np: s.np,
        intensityFactor: s.intensity_factor ?? s.if ?? null,
        tss: s.tss,
        pwHr: s.pw_hr,
        pdc: s.pdc,
        density: s.density,
      })),
      weekly: apiData.weekly || {},
      weeklyBySport: apiData.weekly_by_sport || {},
      trends: {
        bikePdc20minSlope: apiData.trends?.bike_pdc_20min_slope ?? null,
        bikePdc60minSlope: apiData.trends?.bike_pdc_60min_slope ?? null,
      },
      decisions: (apiData.decisions || []).map(d => ({
        ruleId: d.rule_id,
        label: d.label,
        severity: d.severity as 'info' | 'warning' | 'critical',
        evidence: d.evidence,
      })),
      radar: {
        aerobicEndurance: apiData.radar?.aerobic_endurance ?? 0,
        thresholdDurability: apiData.radar?.threshold_durability ?? 0,
        vo2Hi: apiData.radar?.vo2_hi ?? 0,
        techniqueEconomy: apiData.radar?.technique_economy ?? 0,
        consistencyLoad: apiData.radar?.consistency_load ?? 0,
        overall: apiData.radar?.overall ?? 0,
      },
      profile: {
        hrMax: apiData.profile?.hr_max ?? null,
        weightKg: apiData.profile?.weight_kg ?? null,
        cyclingCp: apiData.profile?.cycling_cp ?? null,
        cyclingFtp: apiData.profile?.cycling_ftp ?? null,
        runningCsMs: apiData.profile?.running_cs_ms ?? null,
        runningVma: apiData.profile?.running_vma ?? null,
        swimmingCss: apiData.profile?.swimming_css ?? null,
      },
      meta: {
        computedAt: apiData.meta?.computed_at ?? new Date().toISOString(),
        daysAnalyzed: apiData.meta?.days_analyzed ?? 90,
        sportsAnalyzed: apiData.meta?.sports_analyzed ?? [],
      },
    };
  }

  // ============ HELPERS DE FORMATAGE ============

  /**
   * Obtenir la couleur du statut TSB
   */
  getTsbStatusColor(status: TrainingLoadStatus): string {
    const colors: Record<TrainingLoadStatus, string> = {
      fresh: '#10B981', // green
      ready: '#3B82F6', // blue
      neutral: '#6B7280', // gray
      tired: '#F59E0B', // amber
      overreached: '#EF4444', // red
      unknown: '#9CA3AF', // gray light
    };
    return colors[status];
  }

  /**
   * Interpréter le TSB en statut
   */
  interpretTsb(tsb: number | null): { status: TrainingLoadStatus; label: string } {
    if (tsb === null) {
      return { status: 'unknown', label: 'Données insuffisantes' };
    }
    if (tsb > 25) {
      return { status: 'fresh', label: 'Très frais' };
    }
    if (tsb > 5) {
      return { status: 'ready', label: 'Prêt à performer' };
    }
    if (tsb > -10) {
      return { status: 'neutral', label: 'Équilibré' };
    }
    if (tsb > -25) {
      return { status: 'tired', label: 'Fatigué' };
    }
    return { status: 'overreached', label: 'Surcharge' };
  }

  /**
   * Formater un score radar (0-100) en texte
   */
  formatRadarScore(score: number): string {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    if (score >= 20) return 'À améliorer';
    return 'Faible';
  }

  /**
   * Obtenir l'icône du sport
   */
  getSportIcon(sport: string): string {
    const icons: Record<string, string> = {
      running: 'walk',
      cycling: 'bicycle',
      swimming: 'water',
    };
    return icons[sport] || 'fitness';
  }

  /**
   * Formater la monotonie
   */
  formatMonotony(monotony: number | null): { value: string; status: 'good' | 'warning' | 'danger' } {
    if (monotony === null) {
      return { value: '--', status: 'good' };
    }
    const value = monotony.toFixed(2);
    if (monotony < 1.2) {
      return { value, status: 'good' }; // Variété suffisante
    }
    if (monotony < 2.0) {
      return { value, status: 'warning' }; // Optimal
    }
    return { value, status: 'danger' }; // Trop monotone, risque de surentraînement
  }

  /**
   * Formater la PDC en texte lisible
   */
  formatPdc(pdc: PDCData | null): string[] {
    if (!pdc) return [];
    const labels: Array<{ key: keyof PDCData; label: string }> = [
      { key: '5', label: '5s' },
      { key: '60', label: '1min' },
      { key: '300', label: '5min' },
      { key: '1200', label: '20min' },
      { key: '3600', label: '60min' },
    ];
    return labels
      .filter(l => pdc[l.key] !== null)
      .map(l => `${l.label}: ${pdc[l.key]}W`);
  }

  /**
   * Calculer le ratio W/kg si poids disponible
   */
  calculateWPerKg(watts: number | null, weightKg: number | null): string {
    if (!watts || !weightKg || weightKg === 0) return '--';
    return (watts / weightKg).toFixed(2);
  }
}

export const statsAdvancedService = new StatsAdvancedService();
export default statsAdvancedService;
