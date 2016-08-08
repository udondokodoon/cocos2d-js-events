LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := liquidfun_static

LOCAL_MODULE_FILENAME := libliquidfun

LOCAL_SRC_FILES := \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2BroadPhase.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2CollideCircle.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2CollideEdge.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2CollidePolygon.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2Collision.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2Distance.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2DynamicTree.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/b2TimeOfImpact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/Shapes/b2ChainShape.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/Shapes/b2CircleShape.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/Shapes/b2EdgeShape.cpp \
liquidfun/liquidfun/Box2D/Box2D/Collision/Shapes/b2PolygonShape.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2BlockAllocator.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2Draw.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2FreeList.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2Math.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2Settings.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2StackAllocator.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2Stat.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2Timer.cpp \
liquidfun/liquidfun/Box2D/Box2D/Common/b2TrackedBlock.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/b2Body.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/b2ContactManager.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/b2Fixture.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/b2Island.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/b2World.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/b2WorldCallbacks.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2ChainAndCircleContact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2ChainAndPolygonContact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2CircleContact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2Contact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2ContactSolver.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2EdgeAndCircleContact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2EdgeAndPolygonContact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2PolygonAndCircleContact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Contacts/b2PolygonContact.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2DistanceJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2FrictionJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2GearJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2Joint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2MotorJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2MouseJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2PrismaticJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2PulleyJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2RevoluteJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2RopeJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2WeldJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Dynamics/Joints/b2WheelJoint.cpp \
liquidfun/liquidfun/Box2D/Box2D/Particle/b2Particle.cpp \
liquidfun/liquidfun/Box2D/Box2D/Particle/b2ParticleGroup.cpp \
liquidfun/liquidfun/Box2D/Box2D/Particle/b2ParticleSystem.cpp \
liquidfun/liquidfun/Box2D/Box2D/Particle/b2VoronoiDiagram.cpp \
liquidfun/liquidfun/Box2D/Box2D/Rope/b2Rope.cpp

LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/liquidfun/liquidfun/Box2D

LOCAL_C_INCLUDES := $(LOCAL_PATH)/liquidfun/liquidfun/Box2D
                                 
include $(BUILD_STATIC_LIBRARY)
