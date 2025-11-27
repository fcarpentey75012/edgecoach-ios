/**
 * Écran de création de plan d'entraînement
 * Version condensée en 3 étapes
 */

import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Alert,
  KeyboardAvoidingView,
  Platform,
  Animated,
  ActivityIndicator,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import { useAuth } from '../contexts/AuthContext';
import { colors, spacing, typography } from '../theme';
import { plansService } from '../services/plansService';
import apiService from '../services/api';

type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

// Types
interface FormData {
  sport: string;
  experience: string;
  objectives: string[];
  customObjective: string;
  duration: number;
  startDate: Date;
  weeklyHours: number;
  constraints: string;
  unavailableDays: string[];
}

// Constantes
const SPORTS = [
  { id: 'triathlon', label: 'Triathlon', icon: 'trophy-outline', color: colors.sports.triathlon },
  { id: 'running', label: 'Course à pied', icon: 'walk-outline', color: colors.sports.running },
  { id: 'cycling', label: 'Cyclisme', icon: 'bicycle-outline', color: colors.sports.cycling },
  { id: 'swimming', label: 'Natation', icon: 'water-outline', color: colors.sports.swimming },
];

const EXPERIENCE_LEVELS = [
  { id: 'beginner', label: 'Débutant', description: 'Moins de 1 an de pratique' },
  { id: 'intermediate', label: 'Intermédiaire', description: '1 à 3 ans de pratique' },
  { id: 'advanced', label: 'Avancé', description: '3 à 5 ans de pratique' },
  { id: 'expert', label: 'Expert', description: 'Plus de 5 ans de pratique' },
];

const OBJECTIVES = [
  { id: 'endurance', label: 'Améliorer l\'endurance', icon: 'heart-outline' },
  { id: 'speed', label: 'Gagner en vitesse', icon: 'flash-outline' },
  { id: 'strength', label: 'Renforcer la puissance', icon: 'fitness-outline' },
  { id: 'technique', label: 'Améliorer la technique', icon: 'body-outline' },
  { id: 'competition', label: 'Préparer une compétition', icon: 'trophy-outline' },
  { id: 'weight_loss', label: 'Perdre du poids', icon: 'scale-outline' },
];

const DURATION_PRESETS = [4, 8, 12, 16];

const DAYS_OF_WEEK = [
  { id: 'monday', label: 'Lun' },
  { id: 'tuesday', label: 'Mar' },
  { id: 'wednesday', label: 'Mer' },
  { id: 'thursday', label: 'Jeu' },
  { id: 'friday', label: 'Ven' },
  { id: 'saturday', label: 'Sam' },
  { id: 'sunday', label: 'Dim' },
];

const TrainingPlanCreatorScreen: React.FC = () => {
  const navigation = useNavigation<NavigationProp>();
  const { user } = useAuth();
  const scrollViewRef = useRef<ScrollView>(null);

  // État du formulaire
  const [currentStep, setCurrentStep] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState<FormData>({
    sport: '',
    experience: user?.experience || '',
    objectives: [],
    customObjective: '',
    duration: 8,
    startDate: getNextMonday(),
    weeklyHours: 6,
    constraints: '',
    unavailableDays: [],
  });

  // Animation
  const fadeAnim = useRef(new Animated.Value(1)).current;

  // Pré-sélectionner le niveau d'expérience de l'utilisateur
  useEffect(() => {
    if (user?.experience && !formData.experience) {
      setFormData(prev => ({ ...prev, experience: user.experience }));
    }
  }, [user?.experience]);

  // Helpers
  function getNextMonday(): Date {
    const today = new Date();
    const dayOfWeek = today.getDay();
    const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek;
    const nextMonday = new Date(today);
    nextMonday.setDate(today.getDate() + daysUntilMonday);
    return nextMonday;
  }

  function formatDate(date: Date): string {
    return date.toLocaleDateString('fr-FR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  }

  // Navigation entre étapes
  const goToStep = (step: number) => {
    Animated.sequence([
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 150,
        useNativeDriver: true,
      }),
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 150,
        useNativeDriver: true,
      }),
    ]).start();

    setTimeout(() => {
      setCurrentStep(step);
      scrollViewRef.current?.scrollTo({ y: 0, animated: true });
    }, 150);
  };

  const canProceed = (): boolean => {
    switch (currentStep) {
      case 0:
        return formData.sport !== '' && formData.experience !== '';
      case 1:
        const hasObjective = formData.objectives.length > 0 || formData.customObjective.trim().length > 0;
        return hasObjective && formData.duration > 0 && formData.duration <= 52;
      case 2:
        return true;
      default:
        return false;
    }
  };

  // Soumission du formulaire
  const handleSubmit = async () => {
    if (!user?.id) {
      Alert.alert('Erreur', 'Vous devez être connecté pour créer un plan.');
      return;
    }

    setIsSubmitting(true);

    try {
      // Préparer les objectifs (combiner prédéfinis + personnalisé)
      const allObjectives = [...formData.objectives];
      if (formData.customObjective.trim()) {
        allObjectives.push(`custom:${formData.customObjective.trim()}`);
      }

      // Préparer les données pour l'API
      const planRequest = {
        user_id: user.id,
        sport: formData.sport,
        experience_level: formData.experience,
        objectives: allObjectives,
        custom_objective: formData.customObjective.trim() || undefined,
        duration_weeks: formData.duration,
        start_date: formData.startDate.toISOString().split('T')[0],
        weekly_hours: formData.weeklyHours,
        constraints: formData.constraints || undefined,
        unavailable_days: formData.unavailableDays.length > 0 ? formData.unavailableDays : undefined,
        language: 'fr',
      };

      // Appeler l'API de génération de plan
      const response = await apiService.post('/plans/generate', planRequest);

      Alert.alert(
        'Plan créé !',
        'Votre plan d\'entraînement a été généré avec succès. Retrouvez-le dans votre calendrier.',
        [
          {
            text: 'Voir le calendrier',
            onPress: () => {
              navigation.goBack();
              // Navigation vers le calendrier sera gérée par le parent
            },
          },
        ]
      );
    } catch (error: any) {
      console.error('Error creating plan:', error);
      Alert.alert(
        'Erreur',
        error.message || 'Une erreur est survenue lors de la création du plan. Veuillez réessayer.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  // Rendu de l'étape 1 : Sport & Niveau
  const renderStep1 = () => (
    <View style={styles.stepContent}>
      <Text style={styles.stepTitle}>Sport & Niveau</Text>
      <Text style={styles.stepDescription}>
        Choisissez votre sport et indiquez votre niveau d'expérience
      </Text>

      {/* Sélection du sport */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Sport principal</Text>
        <View style={styles.sportGrid}>
          {SPORTS.map(sport => (
            <TouchableOpacity
              key={sport.id}
              style={[
                styles.sportCard,
                formData.sport === sport.id && styles.sportCardSelected,
                formData.sport === sport.id && { borderColor: sport.color },
              ]}
              onPress={() => setFormData({ ...formData, sport: sport.id })}
            >
              <Icon
                name={sport.icon}
                size={32}
                color={formData.sport === sport.id ? sport.color : colors.neutral.gray[400]}
              />
              <Text
                style={[
                  styles.sportLabel,
                  formData.sport === sport.id && { color: sport.color },
                ]}
              >
                {sport.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Sélection du niveau */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Niveau d'expérience</Text>
        {EXPERIENCE_LEVELS.map(level => (
          <TouchableOpacity
            key={level.id}
            style={[
              styles.levelCard,
              formData.experience === level.id && styles.levelCardSelected,
            ]}
            onPress={() => setFormData({ ...formData, experience: level.id })}
          >
            <View style={styles.levelRadio}>
              {formData.experience === level.id && (
                <View style={styles.levelRadioInner} />
              )}
            </View>
            <View style={styles.levelContent}>
              <Text style={styles.levelLabel}>{level.label}</Text>
              <Text style={styles.levelDescription}>{level.description}</Text>
            </View>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );

  // Rendu de l'étape 2 : Objectifs & Planning
  const renderStep2 = () => (
    <View style={styles.stepContent}>
      <Text style={styles.stepTitle}>Objectifs & Planning</Text>
      <Text style={styles.stepDescription}>
        Définissez vos objectifs et la durée de votre programme
      </Text>

      {/* Objectifs prédéfinis */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Objectifs rapides (optionnel)</Text>
        <View style={styles.objectivesGrid}>
          {OBJECTIVES.map(objective => {
            const isSelected = formData.objectives.includes(objective.id);
            return (
              <TouchableOpacity
                key={objective.id}
                style={[
                  styles.objectiveCard,
                  isSelected && styles.objectiveCardSelected,
                ]}
                onPress={() => {
                  const newObjectives = isSelected
                    ? formData.objectives.filter(o => o !== objective.id)
                    : [...formData.objectives, objective.id];
                  setFormData({ ...formData, objectives: newObjectives });
                }}
              >
                <Icon
                  name={objective.icon}
                  size={24}
                  color={isSelected ? colors.primary[500] : colors.neutral.gray[400]}
                />
                <Text
                  style={[
                    styles.objectiveLabel,
                    isSelected && styles.objectiveLabelSelected,
                  ]}
                >
                  {objective.label}
                </Text>
                {isSelected && (
                  <Icon
                    name="checkmark-circle"
                    size={20}
                    color={colors.primary[500]}
                    style={styles.objectiveCheck}
                  />
                )}
              </TouchableOpacity>
            );
          })}
        </View>
      </View>

      {/* Objectif personnalisé */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Mon objectif personnel</Text>
        <TextInput
          style={styles.customObjectiveInput}
          placeholder="Ex: Préparer le triathlon de Nice en juin, finir en moins de 3h..."
          placeholderTextColor={colors.neutral.gray[400]}
          multiline
          numberOfLines={3}
          value={formData.customObjective}
          onChangeText={(text) => setFormData({ ...formData, customObjective: text })}
          textAlignVertical="top"
        />
        <Text style={styles.inputHint}>
          Décrivez votre objectif en quelques mots ou phrases
        </Text>
      </View>

      {/* Durée personnalisable */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Durée du programme</Text>

        {/* Boutons de présets */}
        <View style={styles.durationPresets}>
          {DURATION_PRESETS.map(weeks => (
            <TouchableOpacity
              key={weeks}
              style={[
                styles.durationPresetButton,
                formData.duration === weeks && styles.durationPresetButtonSelected,
              ]}
              onPress={() => setFormData({ ...formData, duration: weeks })}
            >
              <Text
                style={[
                  styles.durationPresetText,
                  formData.duration === weeks && styles.durationPresetTextSelected,
                ]}
              >
                {weeks} sem.
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Sélecteur personnalisé */}
        <View style={styles.durationCustomContainer}>
          <TouchableOpacity
            style={styles.durationButton}
            onPress={() => setFormData({ ...formData, duration: Math.max(1, formData.duration - 1) })}
          >
            <Icon name="remove" size={24} color={colors.primary[500]} />
          </TouchableOpacity>

          <View style={styles.durationInputContainer}>
            <TextInput
              style={styles.durationInput}
              value={String(formData.duration)}
              onChangeText={(text) => {
                const num = parseInt(text, 10);
                if (!isNaN(num) && num >= 1 && num <= 52) {
                  setFormData({ ...formData, duration: num });
                } else if (text === '') {
                  setFormData({ ...formData, duration: 0 });
                }
              }}
              keyboardType="number-pad"
              maxLength={2}
            />
            <Text style={styles.durationInputLabel}>semaines</Text>
          </View>

          <TouchableOpacity
            style={styles.durationButton}
            onPress={() => setFormData({ ...formData, duration: Math.min(52, formData.duration + 1) })}
          >
            <Icon name="add" size={24} color={colors.primary[500]} />
          </TouchableOpacity>
        </View>

        <Text style={styles.inputHint}>
          De 1 à 52 semaines selon votre objectif
        </Text>
      </View>

      {/* Volume horaire */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Volume horaire hebdomadaire</Text>
        <View style={styles.hoursContainer}>
          <TouchableOpacity
            style={styles.hoursButton}
            onPress={() => setFormData({ ...formData, weeklyHours: Math.max(2, formData.weeklyHours - 1) })}
          >
            <Icon name="remove" size={24} color={colors.primary[500]} />
          </TouchableOpacity>
          <View style={styles.hoursDisplay}>
            <Text style={styles.hoursValue}>{formData.weeklyHours}</Text>
            <Text style={styles.hoursUnit}>heures/semaine</Text>
          </View>
          <TouchableOpacity
            style={styles.hoursButton}
            onPress={() => setFormData({ ...formData, weeklyHours: Math.min(20, formData.weeklyHours + 1) })}
          >
            <Icon name="add" size={24} color={colors.primary[500]} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Date de début */}
      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Date de début</Text>
        <View style={styles.dateCard}>
          <Icon name="calendar-outline" size={24} color={colors.primary[500]} />
          <Text style={styles.dateText}>{formatDate(formData.startDate)}</Text>
        </View>
        <View style={styles.quickDates}>
          <TouchableOpacity
            style={styles.quickDateButton}
            onPress={() => setFormData({ ...formData, startDate: getNextMonday() })}
          >
            <Text style={styles.quickDateText}>Lundi prochain</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.quickDateButton}
            onPress={() => {
              const date = getNextMonday();
              date.setDate(date.getDate() + 7);
              setFormData({ ...formData, startDate: date });
            }}
          >
            <Text style={styles.quickDateText}>Dans 2 semaines</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );

  // Rendu de l'étape 3 : Récapitulatif
  const renderStep3 = () => {
    const selectedSport = SPORTS.find(s => s.id === formData.sport);
    const selectedLevel = EXPERIENCE_LEVELS.find(l => l.id === formData.experience);
    const selectedObjectives = OBJECTIVES.filter(o => formData.objectives.includes(o.id));

    return (
      <View style={styles.stepContent}>
        <Text style={styles.stepTitle}>Récapitulatif</Text>
        <Text style={styles.stepDescription}>
          Vérifiez vos choix avant de générer votre plan
        </Text>

        {/* Résumé */}
        <View style={styles.summaryCard}>
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Sport</Text>
            <View style={styles.summaryValue}>
              <Icon
                name={selectedSport?.icon || 'help-outline'}
                size={18}
                color={selectedSport?.color || colors.neutral.gray[400]}
              />
              <Text style={styles.summaryText}>{selectedSport?.label}</Text>
            </View>
          </View>

          <View style={styles.summaryDivider} />

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Niveau</Text>
            <Text style={styles.summaryText}>{selectedLevel?.label}</Text>
          </View>

          <View style={styles.summaryDivider} />

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Objectifs</Text>
            <View style={styles.summaryObjectives}>
              {selectedObjectives.map(obj => (
                <View key={obj.id} style={styles.summaryObjectiveBadge}>
                  <Text style={styles.summaryObjectiveText}>{obj.label}</Text>
                </View>
              ))}
            </View>
          </View>

          {formData.customObjective.trim() && (
            <>
              <View style={styles.summaryDivider} />
              <View style={styles.summaryRowColumn}>
                <Text style={styles.summaryLabel}>Objectif personnel</Text>
                <Text style={styles.summaryCustomObjective}>
                  "{formData.customObjective.trim()}"
                </Text>
              </View>
            </>
          )}

          <View style={styles.summaryDivider} />

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Durée</Text>
            <Text style={styles.summaryText}>{formData.duration} semaines</Text>
          </View>

          <View style={styles.summaryDivider} />

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Volume</Text>
            <Text style={styles.summaryText}>{formData.weeklyHours}h / semaine</Text>
          </View>

          <View style={styles.summaryDivider} />

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Début</Text>
            <Text style={styles.summaryText}>{formatDate(formData.startDate)}</Text>
          </View>
        </View>

        {/* Contraintes optionnelles */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Contraintes ou précisions (optionnel)</Text>
          <TextInput
            style={styles.constraintsInput}
            placeholder="Ex: Je ne peux pas nager le mardi, je prépare un triathlon M en juin..."
            placeholderTextColor={colors.neutral.gray[400]}
            multiline
            numberOfLines={4}
            value={formData.constraints}
            onChangeText={(text) => setFormData({ ...formData, constraints: text })}
            textAlignVertical="top"
          />
        </View>

        {/* Jours indisponibles */}
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Jours indisponibles (optionnel)</Text>
          <View style={styles.daysGrid}>
            {DAYS_OF_WEEK.map(day => {
              const isUnavailable = formData.unavailableDays.includes(day.id);
              return (
                <TouchableOpacity
                  key={day.id}
                  style={[
                    styles.dayButton,
                    isUnavailable && styles.dayButtonSelected,
                  ]}
                  onPress={() => {
                    const newDays = isUnavailable
                      ? formData.unavailableDays.filter(d => d !== day.id)
                      : [...formData.unavailableDays, day.id];
                    setFormData({ ...formData, unavailableDays: newDays });
                  }}
                >
                  <Text
                    style={[
                      styles.dayButtonText,
                      isUnavailable && styles.dayButtonTextSelected,
                    ]}
                  >
                    {day.label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>
      </View>
    );
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <Icon name="arrow-back" size={24} color={colors.secondary[800]} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Nouveau plan</Text>
        <View style={styles.headerRight} />
      </View>

      {/* Progress Indicator */}
      <View style={styles.progressContainer}>
        {[0, 1, 2].map(step => (
          <React.Fragment key={step}>
            <TouchableOpacity
              style={[
                styles.progressStep,
                currentStep >= step && styles.progressStepActive,
                currentStep === step && styles.progressStepCurrent,
              ]}
              onPress={() => step < currentStep && goToStep(step)}
              disabled={step > currentStep}
            >
              <Text
                style={[
                  styles.progressStepText,
                  currentStep >= step && styles.progressStepTextActive,
                ]}
              >
                {step + 1}
              </Text>
            </TouchableOpacity>
            {step < 2 && (
              <View
                style={[
                  styles.progressLine,
                  currentStep > step && styles.progressLineActive,
                ]}
              />
            )}
          </React.Fragment>
        ))}
      </View>

      {/* Content */}
      <ScrollView
        ref={scrollViewRef}
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        <Animated.View style={{ opacity: fadeAnim }}>
          {currentStep === 0 && renderStep1()}
          {currentStep === 1 && renderStep2()}
          {currentStep === 2 && renderStep3()}
        </Animated.View>
      </ScrollView>

      {/* Footer */}
      <View style={styles.footer}>
        {currentStep > 0 && (
          <TouchableOpacity
            style={styles.secondaryButton}
            onPress={() => goToStep(currentStep - 1)}
          >
            <Text style={styles.secondaryButtonText}>Retour</Text>
          </TouchableOpacity>
        )}

        <TouchableOpacity
          style={[
            styles.primaryButton,
            !canProceed() && styles.primaryButtonDisabled,
            currentStep === 0 && styles.primaryButtonFull,
          ]}
          onPress={() => {
            if (currentStep < 2) {
              goToStep(currentStep + 1);
            } else {
              handleSubmit();
            }
          }}
          disabled={!canProceed() || isSubmitting}
        >
          {isSubmitting ? (
            <ActivityIndicator color={colors.neutral.white} />
          ) : (
            <>
              <Text style={styles.primaryButtonText}>
                {currentStep < 2 ? 'Continuer' : 'Générer mon plan'}
              </Text>
              {currentStep < 2 && (
                <Icon name="arrow-forward" size={20} color={colors.neutral.white} />
              )}
            </>
          )}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.md,
    paddingTop: spacing.xl,
    paddingBottom: spacing.md,
    backgroundColor: colors.neutral.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
  },
  backButton: {
    padding: spacing.xs,
  },
  headerTitle: {
    ...typography.styles.h3,
    color: colors.secondary[800],
  },
  headerRight: {
    width: 32,
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.lg,
    backgroundColor: colors.neutral.white,
  },
  progressStep: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.neutral.gray[200],
    justifyContent: 'center',
    alignItems: 'center',
  },
  progressStepActive: {
    backgroundColor: colors.primary[500],
  },
  progressStepCurrent: {
    backgroundColor: colors.primary[500],
    transform: [{ scale: 1.1 }],
  },
  progressStepText: {
    ...typography.styles.label,
    color: colors.neutral.gray[500],
  },
  progressStepTextActive: {
    color: colors.neutral.white,
  },
  progressLine: {
    width: 40,
    height: 2,
    backgroundColor: colors.neutral.gray[200],
    marginHorizontal: spacing.xs,
  },
  progressLineActive: {
    backgroundColor: colors.primary[500],
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing.md,
    paddingBottom: spacing.xl,
  },
  stepContent: {},
  stepTitle: {
    ...typography.styles.h2,
    color: colors.secondary[800],
    marginBottom: spacing.xs,
  },
  stepDescription: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginBottom: spacing.lg,
  },
  section: {
    marginBottom: spacing.lg,
  },
  sectionLabel: {
    ...typography.styles.label,
    color: colors.secondary[700],
    marginBottom: spacing.sm,
  },
  // Sport selection
  sportGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
  },
  sportCard: {
    width: '48%',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: colors.neutral.gray[200],
  },
  sportCardSelected: {
    borderWidth: 2,
    backgroundColor: colors.primary[50],
  },
  sportLabel: {
    ...typography.styles.label,
    color: colors.neutral.gray[600],
    marginTop: spacing.sm,
  },
  // Experience levels
  levelCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 2,
    borderColor: colors.neutral.gray[200],
  },
  levelCardSelected: {
    borderColor: colors.primary[500],
    backgroundColor: colors.primary[50],
  },
  levelRadio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: colors.neutral.gray[300],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  levelRadioInner: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.primary[500],
  },
  levelContent: {
    flex: 1,
  },
  levelLabel: {
    ...typography.styles.body,
    fontWeight: '600',
    color: colors.secondary[800],
  },
  levelDescription: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: 2,
  },
  // Objectives
  objectivesGrid: {
    gap: spacing.sm,
  },
  objectiveCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    borderWidth: 2,
    borderColor: colors.neutral.gray[200],
  },
  objectiveCardSelected: {
    borderColor: colors.primary[500],
    backgroundColor: colors.primary[50],
  },
  objectiveLabel: {
    ...typography.styles.body,
    color: colors.secondary[700],
    marginLeft: spacing.md,
    flex: 1,
  },
  objectiveLabelSelected: {
    color: colors.primary[700],
    fontWeight: '500',
  },
  objectiveCheck: {
    marginLeft: spacing.sm,
  },
  // Custom objective
  customObjectiveInput: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    ...typography.styles.body,
    color: colors.secondary[800],
    minHeight: 80,
    borderWidth: 1,
    borderColor: colors.neutral.gray[200],
  },
  inputHint: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    marginTop: spacing.xs,
  },
  // Duration
  durationPresets: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  durationPresetButton: {
    flex: 1,
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    paddingVertical: spacing.sm,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: colors.neutral.gray[200],
  },
  durationPresetButtonSelected: {
    borderColor: colors.primary[500],
    backgroundColor: colors.primary[50],
  },
  durationPresetText: {
    ...typography.styles.label,
    color: colors.neutral.gray[600],
  },
  durationPresetTextSelected: {
    color: colors.primary[600],
    fontWeight: '600',
  },
  durationCustomContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
  },
  durationButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.primary[50],
    justifyContent: 'center',
    alignItems: 'center',
  },
  durationInputContainer: {
    alignItems: 'center',
    marginHorizontal: spacing.lg,
  },
  durationInput: {
    ...typography.styles.h1,
    color: colors.primary[500],
    textAlign: 'center',
    minWidth: 60,
    padding: 0,
  },
  durationInputLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  // Hours
  hoursContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
  },
  hoursButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.primary[50],
    justifyContent: 'center',
    alignItems: 'center',
  },
  hoursDisplay: {
    alignItems: 'center',
    marginHorizontal: spacing.xl,
  },
  hoursValue: {
    ...typography.styles.h1,
    color: colors.primary[500],
  },
  hoursUnit: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  // Date
  dateCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    gap: spacing.md,
  },
  dateText: {
    ...typography.styles.body,
    color: colors.secondary[800],
    textTransform: 'capitalize',
  },
  quickDates: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginTop: spacing.sm,
  },
  quickDateButton: {
    backgroundColor: colors.primary[50],
    paddingVertical: spacing.xs,
    paddingHorizontal: spacing.md,
    borderRadius: spacing.borderRadius.full,
  },
  quickDateText: {
    ...typography.styles.caption,
    color: colors.primary[600],
  },
  // Summary
  summaryCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    marginBottom: spacing.lg,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingVertical: spacing.sm,
  },
  summaryLabel: {
    ...typography.styles.label,
    color: colors.neutral.gray[500],
  },
  summaryValue: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  summaryText: {
    ...typography.styles.body,
    color: colors.secondary[800],
    fontWeight: '500',
  },
  summaryObjectives: {
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'flex-end',
    gap: spacing.xs,
  },
  summaryObjectiveBadge: {
    backgroundColor: colors.primary[50],
    paddingVertical: 4,
    paddingHorizontal: spacing.sm,
    borderRadius: spacing.borderRadius.full,
  },
  summaryObjectiveText: {
    ...typography.styles.caption,
    color: colors.primary[600],
  },
  summaryDivider: {
    height: 1,
    backgroundColor: colors.neutral.gray[100],
  },
  summaryRowColumn: {
    paddingVertical: spacing.sm,
  },
  summaryCustomObjective: {
    ...typography.styles.body,
    color: colors.secondary[700],
    fontStyle: 'italic',
    marginTop: spacing.xs,
  },
  // Constraints
  constraintsInput: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    ...typography.styles.body,
    color: colors.secondary[800],
    minHeight: 100,
    borderWidth: 1,
    borderColor: colors.neutral.gray[200],
  },
  // Days
  daysGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  dayButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.neutral.white,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.neutral.gray[200],
  },
  dayButtonSelected: {
    backgroundColor: colors.status.error + '20',
    borderColor: colors.status.error,
  },
  dayButtonText: {
    ...typography.styles.caption,
    color: colors.secondary[700],
    fontWeight: '500',
  },
  dayButtonTextSelected: {
    color: colors.status.error,
  },
  // Footer
  footer: {
    flexDirection: 'row',
    padding: spacing.md,
    gap: spacing.sm,
    backgroundColor: colors.neutral.white,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[200],
  },
  primaryButton: {
    flex: 1,
    flexDirection: 'row',
    backgroundColor: colors.primary[500],
    paddingVertical: spacing.md,
    borderRadius: spacing.borderRadius.lg,
    justifyContent: 'center',
    alignItems: 'center',
    gap: spacing.sm,
  },
  primaryButtonFull: {
    flex: 1,
  },
  primaryButtonDisabled: {
    backgroundColor: colors.neutral.gray[300],
  },
  primaryButtonText: {
    ...typography.styles.button,
    color: colors.neutral.white,
  },
  secondaryButton: {
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.lg,
    borderRadius: spacing.borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.neutral.gray[300],
  },
  secondaryButtonText: {
    ...typography.styles.button,
    color: colors.secondary[700],
  },
});

export default TrainingPlanCreatorScreen;
