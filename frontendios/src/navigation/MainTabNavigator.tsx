/**
 * Navigation principale avec Tab Bar
 */

import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Icon from 'react-native-vector-icons/Ionicons';
import { MainTabParamList } from './types';
import { colors } from '../theme';

// Écrans
import DashboardScreen from '../screens/DashboardScreen';
import CoachChatScreen from '../screens/CoachChatScreen';
import CalendarScreen from '../screens/CalendarScreen';
import StatsScreen from '../screens/StatsScreen';
import ProfileScreen from '../screens/ProfileScreen';

const Tab = createBottomTabNavigator<MainTabParamList>();

// Configuration des icônes pour chaque tab
const TAB_ICONS: Record<keyof MainTabParamList, { focused: string; unfocused: string }> = {
  Dashboard: { focused: 'home', unfocused: 'home-outline' },
  CoachChat: { focused: 'chatbubbles', unfocused: 'chatbubbles-outline' },
  Calendar: { focused: 'calendar', unfocused: 'calendar-outline' },
  Stats: { focused: 'stats-chart', unfocused: 'stats-chart-outline' },
  Profile: { focused: 'person', unfocused: 'person-outline' },
};

// Labels des tabs
const TAB_LABELS: Record<keyof MainTabParamList, string> = {
  Dashboard: 'Accueil',
  CoachChat: 'Coach IA',
  Calendar: 'Calendrier',
  Stats: 'Stats',
  Profile: 'Profil',
};

const MainTabNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          const icons = TAB_ICONS[route.name];
          const iconName = focused ? icons.focused : icons.unfocused;
          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarLabel: TAB_LABELS[route.name],
        tabBarActiveTintColor: colors.primary[500],
        tabBarInactiveTintColor: colors.neutral.gray[400],
        tabBarStyle: {
          backgroundColor: colors.neutral.white,
          borderTopColor: colors.neutral.gray[200],
          paddingTop: 8,
          paddingBottom: 8,
          height: 88,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '500',
          marginTop: 4,
        },
        headerStyle: {
          backgroundColor: colors.neutral.white,
        },
        headerTitleStyle: {
          fontWeight: '600',
          fontSize: 18,
          color: colors.secondary[800],
        },
        headerShadowVisible: false,
      })}
    >
      <Tab.Screen
        name="Dashboard"
        component={DashboardScreen}
        options={{ title: 'EdgeCoach' }}
      />
      <Tab.Screen
        name="CoachChat"
        component={CoachChatScreen}
        options={{ title: 'Coach IA' }}
      />
      <Tab.Screen
        name="Calendar"
        component={CalendarScreen}
        options={{ title: 'Calendrier' }}
      />
      <Tab.Screen
        name="Stats"
        component={StatsScreen}
        options={{ title: 'Statistiques' }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{ title: 'Profil' }}
      />
    </Tab.Navigator>
  );
};

export default MainTabNavigator;
