# Dev Container Configuration

This devcontainer is configured for building a mobile-first toy organizer app using React Native and Expo.

## What's Included

- **Node.js 20 LTS** - Latest stable Node.js runtime
- **Expo CLI** - For React Native development
- **EAS CLI** - Expo Application Services for builds and deployments
- **Git & GitHub CLI** - Version control and GitHub integration
- **TypeScript** - Type-safe development
- **VS Code Extensions**:
  - ESLint & Prettier for code quality
  - Expo Tools for mobile development
  - Tailwind CSS IntelliSense (for styling)
  - GitHub Copilot (if available)

## Getting Started

1. **Open in Container**: VS Code will prompt you to reopen in container, or use Command Palette > "Dev Containers: Reopen in Container"

2. **Initialize your Expo app**:
   ```bash
   npx create-expo-app@latest toy-organizer
   cd toy-organizer
   ```

3. **Start development**:
   ```bash
   npm start
   ```

4. **Test on your device**:
   - Install "Expo Go" app on your iOS/Android device
   - Scan the QR code from the terminal
   - The app will hot-reload as you make changes

## Key Features for Your App

- **Camera Access**: Use `expo-camera` or `expo-image-picker` for photo capture
- **Image Storage**: Use `expo-file-system` and cloud storage (Firebase, Supabase)
- **Database**: Consider Expo SQLite for local storage or Firebase/Supabase for cloud
- **Navigation**: React Navigation for screen management

## Ports

- **8081**: Metro Bundler (React Native bundler)
- **19000**: Expo DevTools web interface
- **19001-19002**: Expo connection ports

## Next Steps

1. Set up your Expo project structure
2. Install camera and image handling packages
3. Configure state management (Context API, Redux, or Zustand)
4. Set up a backend (Firebase, Supabase, or custom API)
5. Implement toy inventory features (add, edit, delete, categorize)
