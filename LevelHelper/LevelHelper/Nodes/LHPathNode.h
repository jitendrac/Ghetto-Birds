//  This file was generated by LevelHelper
//  http://www.levelhelper.org
//
//  LevelHelperLoader.h
//  Created by Bogdan Vladu
//  Copyright 2011 Bogdan Vladu. All rights reserved.
//
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

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#include "Box2D.h"


//notifications
#define LHPathMovementHasEndedNotification @"LHPathMovementHasEndedNotification"
#define LHPathMovementHasChangedPointNotification @"LHPathMovementHasChangedPointNotification"

//user info keys
#define LHPathMovementSpriteObject @"LHPathMovementSpriteObject" //object is LHSprite
#define LHPathMovementUniqueName @"LHPathMovementUniqueName" // object is NSString
#define LHPathMovementPointNumber @"LHPathMovementPointNumber" //object is NSNumber numberWithInt


enum LH_PATH_MOVEMENT_START_POINT
{ 
	LH_PATH_FIRST_POINT,
    LH_PATH_LAST_POINT,
    LH_PATH_INVALID_POINT
};

enum LH_PATH_MOVEMENT_ORIENTATION
{
    LH_NO_ORIENTATION,
    LH_X_AXIT_ORIENTATION,
    LH_Y_AXIS_ORIENTATION,
    LH_INVALID_ORIENTATION
};

@class LHSprite;
@interface LHPathNode : NSObject
{
	__unsafe_unretained LHSprite* sprite;         //week ptr
	NSMutableArray* pathPoints;
    
	float   speed;
	double  interval;
	bool    startAtEndPoint;
	bool    isCyclic;
	bool    restartOtherEnd;
	int     axisOrientation; //0 NO ORIENTATION 1 X 2 Y
    bool    flipX;
    bool    flipY;
    
	int     currentPoint;
	double  elapsed;

	bool    paused;
	float   initialAngle;
    CGPoint prevPathPosition;
	bool    isLine;	
    bool    relativeMovement;
}
@property (readwrite) bool	isCyclic;
@property (readwrite) bool	restartOtherEnd;
@property (readwrite) int	axisOrientation;
@property (readwrite) bool	paused;
@property (readwrite) bool	isLine;
@property (readwrite) bool  flipX;
@property (readwrite) bool  flipY;
@property (readwrite) bool  relativeMovement;

-(id) initPathNodeWithPoints:(NSArray *)points onSprite:(LHSprite*)spr;

-(void)  setSpeed:(float)value;
-(float) speed;

-(void) restart;

-(void) setStartAtEndPoint:(bool)val;
-(bool) startAtEndPoint;

-(void)update:(ccTime)dt;
@end	
