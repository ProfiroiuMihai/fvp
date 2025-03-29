import { useEffect, useState } from 'react';
import { Camera } from 'react-native-camera'; // or your specific camera library

function YourCameraComponent() {
  const [hasPermission, setHasPermission] = useState(null);
  
  useEffect(() => {
    (async () => {
      const { status } = await Camera.requestPermissionsAsync();
      setHasPermission(status === 'granted');
    })();
  }, []);
  
  if (hasPermission === null) {
    return <View><Text>Requesting camera permission...</Text></View>;
  }
  if (hasPermission === false) {
    return <View><Text>No access to camera</Text></View>;
  }
  
  // Rest of your camera component
  // ... existing code ...
} 