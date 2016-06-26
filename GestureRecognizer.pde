
public interface GestureDelegate
{
  void setVisualDebug(boolean visualDebug);
}

public class GestureRecognizer
{
  GestureDelegate delegate;
  
  int leftHandState;
  int rightHandState;
  
  LinkedList<PVector> leftHandPath;
  LinkedList<PVector> rightHandPath;
  
  PVector leftHandStart;
  PVector rightHandStart;
  
  GestureRecognizer(GestureDelegate delegate)
  {
    this.delegate = delegate;
    
    leftHandPath = new LinkedList<PVector>();
    rightHandPath = new LinkedList<PVector>();
  }
  
  void updateWithSkeleton(KSkeleton skeleton)
  {
    //KinectPV2.HandState_Open:
    //KinectPV2.HandState_Closed:
    //KinectPV2.HandState_Lasso:
    //KinectPV2.HandState_NotTracked:
    
    KJoint[] joints = skeleton.getJoints();
    
    KJoint leftHand = joints[KinectPV2.JointType_HandLeft];
    PVector leftHandPosition = new PVector(leftHand.getX(), leftHand.getY(), leftHand.getZ());
    if (leftHand.getState() != this.leftHandState) {
      this.leftHandState = leftHand.getState();
      leftHandPath.clear();
      leftHandStart = leftHandPosition;
    }
    leftHandPath.addLast(leftHandPosition);
    if (leftHandPath.size() > 100) {
      leftHandPath.removeFirst();
    }
    
    KJoint rightHand = joints[KinectPV2.JointType_HandRight];
    PVector rightHandPosition = new PVector(rightHand.getX(), rightHand.getY(), rightHand.getZ());
    if (rightHand.getState() != this.rightHandState) {
      this.rightHandState = rightHand.getState();
      rightHandPath.clear();
      rightHandStart = rightHandPosition;
    }
    rightHandPath.addLast(rightHandPosition);
    if (rightHandPath.size() > 100) {
      rightHandPath.removeFirst();
    }
    
    this.checkDebugGesture();
  }
  
  private void checkDebugGesture()
  {
    if (this.leftHandState == KinectPV2.HandState_Lasso && this.rightHandState == KinectPV2.HandState_Lasso) {
      PVector leftHandPosition = leftHandPath.getLast();
      float leftMovedDistance = leftHandStart.dist(leftHandPosition);
      PVector rightHandPosition = rightHandPath.getLast();
      float rightMovedDistance = rightHandStart.dist(rightHandPosition);

      if (leftMovedDistance > 30 && rightMovedDistance > 30) {
        if (leftHandPosition.x < leftHandStart.x - 20 
            && rightHandPosition.x > rightHandStart.x + 20) {
          delegate.setVisualDebug(true);
        } else if (leftHandPosition.x > leftHandStart.x + 20
            && rightHandPosition.x < rightHandStart.x - 20) {
          delegate.setVisualDebug(false);
        }
      }
    }
  }
}