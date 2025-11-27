/**
 * Service Chat pour EdgeCoach iOS
 * Gestion de la communication avec l'API chat
 * Note: React Native ne supporte pas TextDecoder ni le streaming natif,
 * on utilise donc une approche sans streaming
 */

import apiService from './api';

// Types
export interface ChatMessage {
  content: string;
  is_ai: boolean;
  timestamp?: string;
}

export interface SendMessageOptions {
  onChunk?: (chunk: string) => void;
  onComplete?: (fullResponse: string) => void;
  onError?: (error: Error) => void;
}

class ChatService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = apiService.getBaseUrl().replace('/api', '');
  }

  /**
   * Envoyer un message au coach IA
   * Note: Le streaming n'est pas supporté nativement en React Native,
   * on récupère donc la réponse complète
   */
  async sendMessage(
    userId: string,
    message: string,
    conversationHistory: ChatMessage[] = [],
    options: SendMessageOptions = {}
  ): Promise<string> {
    const { onChunk, onComplete, onError } = options;

    try {
      const url = `${this.baseUrl}/api/chat?user_id=${encodeURIComponent(userId)}`;

      const body = JSON.stringify({
        message,
        conversation_history: conversationHistory.map(msg => ({
          content: msg.content,
          is_ai: msg.is_ai,
          timestamp: msg.timestamp || new Date().toISOString(),
        })),
      });

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/plain',
        },
        body,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP error! status: ${response.status}, message: ${errorText}`);
      }

      // Récupérer la réponse complète (pas de streaming en React Native natif)
      const fullResponse = await response.text();

      // Simuler le comportement de streaming en envoyant la réponse complète
      if (onChunk) {
        onChunk(fullResponse);
      }

      if (onComplete) {
        onComplete(fullResponse);
      }

      return fullResponse;
    } catch (error: any) {
      console.error('Chat error:', error);

      if (onError) {
        onError(error);
      }

      throw error;
    }
  }

  /**
   * Envoyer un message et attendre la réponse complète (sans streaming)
   */
  async sendMessageSync(
    userId: string,
    message: string,
    conversationHistory: ChatMessage[] = []
  ): Promise<string> {
    return this.sendMessage(userId, message, conversationHistory);
  }
}

export const chatService = new ChatService();
export default chatService;
