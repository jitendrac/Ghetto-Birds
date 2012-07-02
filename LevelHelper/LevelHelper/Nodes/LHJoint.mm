//  This file was generated by LevelHelper
//  http://www.levelhelper.org
//
//  LevelHelperLoader.mm
//  Created by Bogdan Vladu
//  Copyright 2011 Bogdan Vladu. All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//  The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//  Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//  This notice may not be removed or altered from any source distribution.
//  By "software" the author refers to this code file and not the application 
//  that was used to generate this file.
//
////////////////////////////////////////////////////////////////////////////////
#import "LHJoint.h"
#import "LHSettings.h"
#import "LevelHelperLoader.h"
#import "LHSprite.h"
#import "LHDictionaryExt.h"
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface LevelHelperLoader (LH_JOINT_PRIVATE)
-(void)removeJoint:(LHJoint*)jt;
@end

@implementation LevelHelperLoader (LH_JOINT_PRIVATE)
-(void)removeJoint:(LHJoint*)jt{
   // NSLog(@"REMOVE JOINT %@", [jt uniqueName]);
    if(!jt)return;
    [jointsInLevel removeObjectForKey:[jt uniqueName]];
}
@end

@interface LHJoint (Private)
-(void) createBox2dJointFromDictionary:(NSDictionary*)dictionary;
@end
////////////////////////////////////////////////////////////////////////////////
@implementation LHJoint
@synthesize tag;
@synthesize type;
@synthesize uniqueName;
@synthesize shouldDestroyJointOnDealloc;
////////////////////////////////////////////////////////////////////////////////
-(void) dealloc{		
  //  NSLog(@"LH Joint Dealloc %@", uniqueName);
    if(shouldDestroyJointOnDealloc)
        [self removeJointFromWorld];

#ifndef LH_ARC_ENABLED
    [uniqueName release];
	[super dealloc];
#endif
}
////////////////////////////////////////////////////////////////////////////////
-(id) initWithDictionary:(NSDictionary*)dictionary 
                   world:(b2World*)box2d 
                  loader:(LevelHelperLoader*)pLoader{
    
    self = [super init];
    if (self != nil)
    {
        joint = 0;
        shouldDestroyJointOnDealloc = true;
        uniqueName = [[NSString alloc] initWithString:[dictionary stringForKey:@"UniqueName"]];
        tag = 0;
        type = LH_DISTANCE_JOINT;
        boxWorld = box2d;
        parentLoader = pLoader;
        
        [self createBox2dJointFromDictionary:dictionary];
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////
+(id) jointWithDictionary:(NSDictionary*)dictionary 
                    world:(b2World*)box2d 
                   loader:(LevelHelperLoader*)pLoader{

    if(!dictionary || !box2d || !pLoader) return nil;
    
#ifndef LH_ARC_ENABLED
    return [[[self alloc] initWithDictionary:dictionary world:box2d loader:pLoader] autorelease];
#else
    return [[self alloc] initWithDictionary:dictionary world:box2d loader:pLoader];
#endif

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(b2Joint*)joint{
    return joint;
}
////////////////////////////////////////////////////////////////////////////////
-(bool) removeJointFromWorld{
    

    if(0 != joint)
	{
        b2Body *body = joint->GetBodyA();
        
        if(0 == body)
        {
            body = joint->GetBodyB();
            
            if(0 == body)
                return false;
        }
        b2World* _world = body->GetWorld();
        
        if(0 == _world)
            return false;
        
        _world->DestroyJoint(joint);
        return true;
	}
    return false;
}
////////////////////////////////////////////////////////////////////////////////
-(LHSprite*) spriteA{
    if(joint)
        return [LHSprite spriteForBody:joint->GetBodyA()];
        
    return nil;
}
//------------------------------------------------------------------------------
-(LHSprite*) spriteB{
    if(joint)
        return [LHSprite spriteForBody:joint->GetBodyB()];
    
    return nil;    
}
//------------------------------------------------------------------------------
-(void)removeSelf{
    if(parentLoader){
        if(!boxWorld->IsLocked()){
            [parentLoader removeJoint:self];
        }
        else {
            [[LHSettings sharedInstance] markJointForRemoval:self];
        }
    }
}
//------------------------------------------------------------------------------
-(void) createBox2dJointFromDictionary:(NSDictionary*)dictionary
{
    joint = 0;
    
	if(nil == dictionary)return;
	if(boxWorld == 0)return;
    
    
    LHSprite* sprA  = [parentLoader spriteWithUniqueName:[dictionary stringForKey:@"ObjectA"]];
    b2Body* bodyA   = [sprA body];
	
    LHSprite* sprB  = [parentLoader spriteWithUniqueName:[dictionary stringForKey:@"ObjectB"]];
    b2Body* bodyB   = [sprB body];
	
    CGPoint sprPosA = [sprA position];
    CGPoint sprPosB = [sprB position];
    
    CGSize scaleA   = [sprA realScale];
    CGSize scaleB   = [sprB realScale];

	if(NULL == bodyA || NULL == bodyB ) return;
	
	CGPoint anchorA = [dictionary pointForKey:@"AnchorA"];
	CGPoint anchorB = [dictionary pointForKey:@"AnchorB"];
    
	bool collideConnected = [dictionary boolForKey:@"CollideConnected"];
	
    tag     = [dictionary intForKey:@"Tag"];
    type    = (LH_JOINT_TYPE)[dictionary intForKey:@"Type"];
    
	b2Vec2 posA, posB;
	
    float ptm = [[LHSettings sharedInstance] lhPtmRatio];
	float convertX = [[LHSettings sharedInstance] convertRatio].x;
	float convertY = [[LHSettings sharedInstance] convertRatio].y;
    
    if(![dictionary boolForKey:@"CenterOfMass"])
    {        
        posA = b2Vec2((sprPosA.x + anchorA.x*scaleA.width)/ptm, 
                      (sprPosA.y - anchorA.y*scaleA.height)/ptm);
        
        posB = b2Vec2((sprPosB.x + anchorB.x*scaleB.width)/ptm, 
                      (sprPosB.y - anchorB.y*scaleB.height)/ptm);
        
    }
    else {		
        posA = bodyA->GetWorldCenter();
        posB = bodyB->GetWorldCenter();
    }
	
	if(0 != bodyA && 0 != bodyB)
	{
		switch (type)
		{
			case LH_DISTANCE_JOINT:
			{
				b2DistanceJointDef jointDef;
				
				jointDef.Initialize(bodyA, 
									bodyB, 
									posA,
									posB);
				
				jointDef.collideConnected = collideConnected;
				
				jointDef.frequencyHz    = [dictionary floatForKey:@"Frequency"];
				jointDef.dampingRatio   = [dictionary floatForKey:@"Damping"];
				
				if(0 != boxWorld){
					joint = (b2DistanceJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}	
				break;
				
			case LH_REVOLUTE_JOINT:
			{
				b2RevoluteJointDef jointDef;
				
				jointDef.lowerAngle     = CC_DEGREES_TO_RADIANS([dictionary floatForKey:@"LowerAngle"]);
				jointDef.upperAngle     = CC_DEGREES_TO_RADIANS([dictionary floatForKey:@"UpperAngle"]);
				jointDef.motorSpeed     = [dictionary floatForKey:@"MotorSpeed"];
				jointDef.maxMotorTorque = [dictionary floatForKey:@"MaxTorque"];
				jointDef.enableLimit    = [dictionary boolForKey:@"EnableLimit"];
				jointDef.enableMotor    = [dictionary boolForKey:@"EnableMotor"];
				jointDef.collideConnected = collideConnected;    
				
				jointDef.Initialize(bodyA, bodyB, posA);
				
				if(0 != boxWorld){
					joint = (b2RevoluteJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}
				break;
				
			case LH_PRISMATIC_JOINT:
			{
				b2PrismaticJointDef jointDef;
				
				// Bouncy limit
				CGPoint axisPt = [dictionary pointForKey:@"Axis"];
				
				b2Vec2 axis(axisPt.x, axisPt.y);
				axis.Normalize();
				
				jointDef.Initialize(bodyA, bodyB, posA, axis);
				
				jointDef.motorSpeed     = [dictionary floatForKey:@"MotorSpeed"];
				jointDef.maxMotorForce  = [dictionary floatForKey:@"MaxMotorForce"];
				
				jointDef.lowerTranslation =  CC_DEGREES_TO_RADIANS([dictionary floatForKey:@"LowerTranslation"]);
				jointDef.upperTranslation = CC_DEGREES_TO_RADIANS([dictionary floatForKey:@"UpperTranslation"]);
				
				jointDef.enableMotor = [dictionary boolForKey:@"EnableMotor"];
				jointDef.enableLimit = [dictionary boolForKey:@"EnableLimit"];
				jointDef.collideConnected = collideConnected;   

				if(0 != boxWorld){
					joint = (b2PrismaticJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}	
				break;
				
			case LH_PULLEY_JOINT:
			{
				b2PulleyJointDef jointDef;
				
				CGPoint grAnchorA = [dictionary pointForKey:@"GroundAnchorA"];
				CGPoint grAnchorB = [dictionary pointForKey:@"GroundAnchorB"];
				
				CGSize winSize = [[CCDirector sharedDirector] winSizeInPixels];
				
				grAnchorA.y = winSize.height - convertY*grAnchorA.y;
				grAnchorB.y = winSize.height - convertY*grAnchorB.y;
				
				b2Vec2 groundAnchorA = b2Vec2(convertX*grAnchorA.x/ptm, grAnchorA.y/ptm);
				b2Vec2 groundAnchorB = b2Vec2(convertX*grAnchorB.x/ptm, grAnchorB.y/ptm);
				
				float ratio = [dictionary floatForKey:@"Ratio"];
				jointDef.Initialize(bodyA, bodyB, groundAnchorA, groundAnchorB, posA, posB, ratio);				
				jointDef.collideConnected = collideConnected;   
				
				if(0 != boxWorld){
					joint = (b2PulleyJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}
				break;
				
			case LH_GEAR_JOINT:
			{
				b2GearJointDef jointDef;
				
				jointDef.bodyA = bodyB;
				jointDef.bodyB = bodyA;
				
				if(bodyA == 0)
					return;
				if(bodyB == 0)
					return;
				
                LHJoint* jointAObj  = [parentLoader jointWithUniqueName:[dictionary stringForKey:@"JointA"]];
                b2Joint* jointA     = [jointAObj joint];
                
                LHJoint* jointBObj  = [parentLoader jointWithUniqueName:[dictionary stringForKey:@"JointB"]];
                b2Joint* jointB     = [jointBObj joint];
                
				if(jointA == 0)
					return;
				if(jointB == 0)
					return;
				
				
				jointDef.joint1 = jointA;
				jointDef.joint2 = jointB;
				
				jointDef.ratio  = [dictionary floatForKey:@"Ratio"];
				jointDef.collideConnected = collideConnected;

				if(0 != boxWorld){
					joint = (b2GearJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}	
				break;
				
				
			case LH_WHEEL_JOINT: //aka line joint
			{
				b2WheelJointDef jointDef;
				
				CGPoint axisPt = [dictionary pointForKey:@"Axis"];
				b2Vec2 axis(axisPt.x, axisPt.y);
				axis.Normalize();
				
				jointDef.motorSpeed     = [dictionary floatForKey:@"MotorSpeed"];
				jointDef.maxMotorTorque = [dictionary floatForKey:@"MaxTorque"];
				jointDef.enableMotor    = [dictionary floatForKey:@"EnableMotor"];
				jointDef.frequencyHz    = [dictionary floatForKey:@"Frequency"];
				jointDef.dampingRatio   = [dictionary floatForKey:@"Damping"];
				
				jointDef.Initialize(bodyA, bodyB, posA, axis);
				jointDef.collideConnected = collideConnected; 
				
				if(0 != boxWorld){
					joint = (b2WheelJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}
				break;				
			case LH_WELD_JOINT:
			{
				b2WeldJointDef jointDef;
				
				jointDef.frequencyHz    = [dictionary floatForKey:@"Frequency"];
				jointDef.dampingRatio   = [dictionary floatForKey:@"Damping"];
				
				jointDef.Initialize(bodyA, bodyB, posA);
				jointDef.collideConnected = collideConnected; 
				
				if(0 != boxWorld){
					joint = (b2WheelJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}
				break;
				
			case LH_ROPE_JOINT: //NOT WORKING YET AS THE BOX2D JOINT FOR THIS TYPE IS A TEST JOINT
			{
				
				b2RopeJointDef jointDef;
				
				jointDef.localAnchorA = bodyA->GetPosition();
				jointDef.localAnchorB = bodyB->GetPosition();
				jointDef.bodyA = bodyA;
				jointDef.bodyB = bodyB;
				jointDef.maxLength = [dictionary floatForKey:@"MaxLength"];
				jointDef.collideConnected = collideConnected; 
				
				if(0 != boxWorld){
					joint = (b2RopeJoint*)boxWorld->CreateJoint(&jointDef);
				}
			}
				break;
				
			case LH_FRICTION_JOINT:
			{
				b2FrictionJointDef jointDef;
				
				jointDef.maxForce   = [dictionary floatForKey:@"MaxForce"];
				jointDef.maxTorque  = [dictionary floatForKey:@"MaxTorque"];
				
				jointDef.Initialize(bodyA, bodyB, posA);
				jointDef.collideConnected = collideConnected; 
				
				if(0 != boxWorld){
					joint = (b2FrictionJoint*)boxWorld->CreateJoint(&jointDef);
				}
				
			}
				break;
				
			default:
				NSLog(@"Unknown joint type in LevelHelper file.");
				break;
		}
	}
    
   
#ifndef LH_ARC_ENABLED
    joint->SetUserData(self);
#else
    joint->SetUserData((__bridge void*)self);
#endif
}


//------------------------------------------------------------------------------
+(bool) isLHJoint:(id)object{   
    if([object isKindOfClass:[LHJoint class]]){
        return true;
    }
    return false;
}
//------------------------------------------------------------------------------
+(LHJoint*) jointFromBox2dJoint:(b2Joint*)jt{    
    if(jt == NULL) return NULL;
    
#ifndef LH_ARC_ENABLED
    id lhJt = (id)jt->GetUserData();
#else
    id lhJt = (__bridge id)jt->GetUserData();
#endif
    
    if([LHJoint isLHJoint:lhJt]){
        return (LHJoint*)lhJt;
    }
    
    return NULL;    
}
//------------------------------------------------------------------------------
+(int) tagFromBox2dJoint:(b2Joint*)joint{
    if(0 != joint){
#ifndef LH_ARC_ENABLED
        LHJoint* data = (LHJoint*)joint->GetUserData();
#else
        LHJoint* data = (__bridge LHJoint*)joint->GetUserData();
#endif
        if(nil != data)return [data tag];
    }
    return -1;
}
//------------------------------------------------------------------------------
+(enum LH_JOINT_TYPE) typeFromBox2dJoint:(b2Joint*)joint{
    if(0 != joint){
#ifndef LH_ARC_ENABLED
        LHJoint* data = (LHJoint*)joint->GetUserData();
#else
        LHJoint* data = (__bridge LHJoint*)joint->GetUserData();
#endif
        if(nil != data) return [data type];
    }
    return LH_UNKNOWN_TYPE;    
}
//------------------------------------------------------------------------------
+(NSString*) uniqueNameFromBox2dJoint:(b2Joint*)joint{
    if(0 != joint){
#ifndef LH_ARC_ENABLED
        LHJoint* data = (LHJoint*)joint->GetUserData();
#else
        LHJoint* data = (__bridge LHJoint*)joint->GetUserData();
#endif
        if(0 != data)return [data uniqueName];
    }
    return nil;
}

@end
