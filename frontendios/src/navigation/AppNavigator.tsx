/**
 * Navigateur principal de l'application
 * Gère la navigation entre Auth et Main selon l'état d'authentification
 */

import React from 'react';
import { ActivityIndicator, View, StyleSheet } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useAuth } from '../contexts/AuthContext';
import { colors } from '../theme';
import { RootStackParamList } from './types';

// Navigateurs
import AuthNavigator from './AuthNavigator';
import MainTabNavigator from './MainTabNavigator';
import SessionDetailScreen from '../screens/SessionDetailScreen';
import ZonesScreen from '../screens/ZonesScreen';
import EquipmentScreen from '../screens/EquipmentScreen';
import TrainingPlanCreatorScreen from '../screens/TrainingPlanCreatorScreen';
import DisciplineSessionsScreen from '../screens/DisciplineSessionsScreen';

const Stack = createNativeStackNavigator<RootStackParamList>();

const AppNavigator: React.FC = () => {
  const { isAuthenticated, isLoading } = useAuth();

  // Écran de chargement pendant la vérification de l'auth
  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary[500]} />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {isAuthenticated ? (
          <>
            <Stack.Screen name="Main" component={MainTabNavigator} />
            <Stack.Screen
              name="SessionDetail"
              component={SessionDetailScreen}
              options={{
                presentation: 'card',
                animation: 'slide_from_right',
              }}
            />
            <Stack.Screen
              name="Zones"
              component={ZonesScreen}
              options={{
                presentation: 'card',
                animation: 'slide_from_right',
              }}
            />
            <Stack.Screen
              name="Equipment"
              component={EquipmentScreen}
              options={{
                presentation: 'card',
                animation: 'slide_from_right',
              }}
            />
            <Stack.Screen
              name="TrainingPlanCreator"
              component={TrainingPlanCreatorScreen}
              options={{
                presentation: 'modal',
                animation: 'slide_from_bottom',
              }}
            />
            <Stack.Screen
              name="DisciplineSessions"
              component={DisciplineSessionsScreen}
              options={{
                headerShown: true,
                presentation: 'card',
                animation: 'slide_from_right',
              }}
            />
          </>
        ) : (
          <Stack.Screen name="Auth" component={AuthNavigator} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
  },
});

export default AppNavigator;
