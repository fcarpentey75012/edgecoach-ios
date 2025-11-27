/**
 * Données des coachs EdgeCoach
 * Miroir des données du frontend web
 */

export type Sport = 'triathlon' | 'running' | 'swimming' | 'cycling';

export interface Coach {
  id: string;
  name: string;
  fullName: string;
  speciality: string;
  description: string;
  avatar: string;
  experience: string;
  expertise: string[];
  sport?: Sport;
}

export const coachProfiles: Record<Sport, Coach[]> = {
  triathlon: [
    {
      id: 'jan_tri',
      name: 'Jan',
      fullName: 'Jan Frodeno',
      speciality: 'Triathlon',
      description: "Expert en triathlon avec 10 ans d'expérience en coaching de haut niveau",
      avatar: 'JT',
      experience: '10+ ans',
      expertise: ['Transition', 'Endurance', 'Stratégie de course'],
    },
    {
      id: 'marie_tri',
      name: 'Marie',
      fullName: 'Marie Leconte',
      speciality: 'Triathlon',
      description: 'Spécialiste en Ironman et ultra-endurance avec focus sur la nutrition sportive',
      avatar: 'MT',
      experience: '8+ ans',
      expertise: ['Ironman', 'Ultra-endurance', 'Nutrition'],
    },
    {
      id: 'thomas_tri',
      name: 'Thomas',
      fullName: 'Thomas Dubois',
      speciality: 'Triathlon',
      description: 'Coach triathlon sprint et olympique spécialisé dans la vitesse et la performance',
      avatar: 'TT',
      experience: '6+ ans',
      expertise: ['Sprint', 'Olympique', 'Vitesse'],
    },
  ],
  running: [
    {
      id: 'eliud_run',
      name: 'Eliud',
      fullName: 'Eliud Kipchoge',
      speciality: 'Course à pied',
      description: 'Champion olympique de course à pied et détenteur du record du monde du marathon',
      avatar: 'EK',
      experience: '15+ ans',
      expertise: ['Marathon', 'Performance', 'Mental'],
    },
    {
      id: 'sophie_run',
      name: 'Sophie',
      fullName: 'Sophie Durand',
      speciality: 'Course à pied',
      description: 'Spécialiste en trail et course nature avec expertise en ultra-endurance',
      avatar: 'SD',
      experience: '7+ ans',
      expertise: ['Trail', 'Ultra-trail', 'Course nature'],
    },
  ],
  swimming: [
    {
      id: 'leon_swim',
      name: 'Léon',
      fullName: 'Léon Marchand',
      speciality: 'Natation',
      description: 'Expert en natation et technique de nage avec spécialisation eau libre',
      avatar: 'LM',
      experience: '12+ ans',
      expertise: ['Technique', 'Eau libre', 'Perfectionnement'],
    },
  ],
  cycling: [
    {
      id: 'remco_bike',
      name: 'Remco',
      fullName: 'Remco Evenepoel',
      speciality: 'Cyclisme',
      description: 'Champion du monde de cyclisme, expert en contre-la-montre et courses par étapes',
      avatar: 'RE',
      experience: '5+ ans',
      expertise: ['Contre-la-montre', 'Montagne', 'Performance'],
    },
  ],
};

export const defaultCoachSelection: Record<Sport, string> = {
  triathlon: 'jan_tri',
  running: 'eliud_run',
  swimming: 'leon_swim',
  cycling: 'remco_bike',
};

export const sportColors: Record<Sport, string> = {
  triathlon: '#8B5CF6', // violet
  running: '#10B981',   // vert
  swimming: '#3B82F6',  // bleu
  cycling: '#F59E0B',   // orange
};

export const sportLabels: Record<Sport, string> = {
  triathlon: 'Triathlon',
  running: 'Course',
  swimming: 'Natation',
  cycling: 'Cyclisme',
};

export const sportIcons: Record<Sport, string> = {
  triathlon: 'trophy',
  running: 'walk',
  swimming: 'water',
  cycling: 'bicycle',
};

// Helper functions
export const getCoachById = (sport: Sport, coachId: string): Coach | null => {
  return coachProfiles[sport]?.find(coach => coach.id === coachId) || null;
};

export const getCoachesBySport = (sport: Sport): Coach[] => {
  return coachProfiles[sport] || [];
};

export const getAllCoaches = (): (Coach & { sport: Sport })[] => {
  const allCoaches: (Coach & { sport: Sport })[] = [];
  (Object.keys(coachProfiles) as Sport[]).forEach(sport => {
    coachProfiles[sport].forEach(coach => {
      allCoaches.push({ ...coach, sport });
    });
  });
  return allCoaches;
};

export const getDefaultCoach = (): Coach & { sport: Sport } => {
  const sport: Sport = 'triathlon';
  const coachId = defaultCoachSelection[sport];
  const coach = getCoachById(sport, coachId)!;
  return { ...coach, sport };
};
