//
//  BouncingScene.m
//  Bouncing
//
//  Created by Seung Kyun Nam on 13. 7. 24..
//  Copyright (c) 2013년 Seung Kyun Nam. All rights reserved.
//

#import "Scene.h"
#import "SKScrollingNode.h"
#import "BirdNode.h"
#import "Score.h"

#define BACK_SCROLLING_SPEED .5
#define FLOOR_SCROLLING_SPEED 3
#define TIME 1.5

@implementation Scene{
    SKScrollingNode * floor;
    SKScrollingNode * back;
    SKLabelNode * scoreLabel;
    BirdNode * bird;
    
    int nbObstacles;
    NSMutableArray * topPipes;
    NSMutableArray * bottomPipes;
}

static bool wasted = NO;

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.physicsWorld.contactDelegate = self;
        [self startGame];
    }
    return self;
}

- (void) startGame
{
    // Reinit
    wasted = NO;
    
    [self removeAllChildren];
    
    [self createBackground];
    [self createFloor];
    [self createScore];
    [self createBird];
    
    // Floor needs to be in front of tubes
    floor.zPosition = bird.zPosition + 1;
    
    if([self.delegate respondsToSelector:@selector(eventStart)]){
        [self.delegate eventStart];
    }
}

#pragma mark - Creations

- (void) createBackground
{
    back = [SKScrollingNode scrollingNodeWithImageNamed:@"back" inContainerWidth:WIDTH(self)];
    [back setScrollingSpeed:BACK_SCROLLING_SPEED];
    [back setAnchorPoint:CGPointZero];
    [back setPhysicsBody:[SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame]];
    back.physicsBody.categoryBitMask = backBitMask;
    back.physicsBody.contactTestBitMask = birdBitMask;
    [self addChild:back];
}

- (void) createScore
{
    self.score = 0;
    scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica-Bold"];
    scoreLabel.text = @"0";
    scoreLabel.fontSize = 500;
    scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 100);
    scoreLabel.alpha = 0.2;
    [self addChild:scoreLabel];
}


- (void)createFloor
{
    floor = [SKScrollingNode scrollingNodeWithImageNamed:@"floor" inContainerWidth:WIDTH(self)];
    [floor setScrollingSpeed:FLOOR_SCROLLING_SPEED];
    [floor setAnchorPoint:CGPointZero];
    [floor setName:@"floor"];
    [floor setPhysicsBody:[SKPhysicsBody bodyWithEdgeLoopFromRect:floor.frame]];
    floor.physicsBody.categoryBitMask = floorBitMask;
    floor.physicsBody.contactTestBitMask = birdBitMask;
    [self addChild:floor];
}

- (void)createBird
{
    bird = [BirdNode new];
    [bird setPosition:CGPointMake(100, CGRectGetMidY(self.frame))];
    [bird setName:@"bird"];
    [self addChild:bird];
}

#pragma mark - Interaction 

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(wasted){
        [self startGame];
    }else{
        if (!bird.physicsBody) {
            [bird startPlaying];
            if([self.delegate respondsToSelector:@selector(eventPlay)]){
                [self.delegate eventPlay];
            }
        }
        [bird bounce];
    }
}

#pragma mark - Update & Core logic


- (void)update:(NSTimeInterval)currentTime
{
    if(wasted){
        return;
    }
    
    // ScrollingNodes
    [back update:currentTime];
    [floor update:currentTime];
    
    // Other
    [bird update:currentTime];
    [self updateObstacles:currentTime];
    [self updateScore:currentTime];
}


- (void) updateObstacles:(NSTimeInterval)currentTime
{
    if(!bird.physicsBody){
        return;
    }
    
}

- (void) updateScore:(NSTimeInterval) currentTime
{

    if (!wasted) {
        CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
        
        if (timeSinceLast > TIME)
        {
            self.lastUpdateTimeInterval = currentTime;

            // Score, adapt font size
            self.score +=1;
            scoreLabel.text = [NSString stringWithFormat:@"%lu",self.score];
            if(self.score>=10){
                scoreLabel.fontSize = 340;
                scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 120);
            }
            if(self.score>=100){
                scoreLabel.fontSize = 200;
                scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), 120);
            }
        }
    }

}

#pragma mark - Physic

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if(wasted){ return; }

    wasted = true;
    [Score registerScore:self.score];
    
    if([self.delegate respondsToSelector:@selector(eventWasted)]){
        [self.delegate eventWasted];
    }
}
@end
