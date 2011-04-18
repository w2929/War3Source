

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new p_xp[MAXPLAYERSCUSTOM][MAXRACES];
new p_level[MAXPLAYERSCUSTOM][MAXRACES];
new p_skilllevel[MAXPLAYERSCUSTOM][MAXRACES][MAXSKILLCOUNT];

new p_properties[MAXPLAYERSCUSTOM][W3PlayerProp];


new bool:bResetSkillsOnSpawn[MAXPLAYERSCUSTOM];
new RaceIDToReset[MAXPLAYERSCUSTOM];


new String:levelupSound[]="war3source/levelupcaster.wav";


new Handle:g_On_Race_Changed;
new Handle:g_On_Race_Selected;
new Handle:g_OnSkillLevelChangedHandle;

public Plugin:myinfo= 
{
	name="W3S Engine player class",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};


public OnPluginStart()
{
	RegConsoleCmd("war3notdev",cmdwar3notdev);
}
public OnMapStart(){
	War3_PrecacheSound(levelupSound);
}

public bool:InitNativesForwards()
{
	g_On_Race_Changed=CreateGlobalForward("OnRaceChanged",ET_Ignore,Param_Cell,Param_Cell);
	g_On_Race_Selected=CreateGlobalForward("OnRaceSelected",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
	g_OnSkillLevelChangedHandle=CreateGlobalForward("OnSkillLevelChanged",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
	
	
	
	CreateNative("War3_SetRace",NWar3_SetRace); //these have forwards to handle
	CreateNative("War3_GetRace",NWar3_GetRace); 
	
	CreateNative("War3_SetLevel",NWar3_SetLevel); //these have forwards to handle
	CreateNative("War3_GetLevel",NWar3_GetLevel); 
	
	CreateNative("War3_SetXP",NWar3_SetXP); //these have forwards to handle
	CreateNative("War3_GetXP",NWar3_GetXP); 
	
	CreateNative("War3_SetSkillLevel",NWar3_SetSkillLevel); //these have forwards to handle
	CreateNative("War3_GetSkillLevel",NWar3_GetSkillLevel); 
	
	
	CreateNative("W3SetPlayerProp",NW3SetPlayerProp);
	CreateNative("W3GetPlayerProp",NW3GetPlayerProp);
	
	CreateNative("W3GetTotalLevels",NW3GetTotalLevels);
	CreateNative("W3GetLevelsSpent",NW3GetLevelsSpent);
	CreateNative("W3ClearSkillLevels",NW3ClearSkillLevels);
	return true;
}

public NWar3_SetRace(Handle:plugin,numParams){
	
	//set old race
	new client=GetNativeCell(1);
	new newrace=GetNativeCell(2);
	if (client > 0 && client <= MaxClients)
	{
		new oldrace=p_properties[client][CurrentRace];
		W3SetVar(OldRace,p_properties[client][CurrentRace]);
		
		if(oldrace>0&&ValidPlayer(client)){
			W3SaveXP(client,oldrace);
		}
		
		
		p_properties[client][CurrentRace]=newrace;
		
		//REMOVE DEPRECATED
		Call_StartForward(g_On_Race_Changed);
		Call_PushCell(client);
		Call_PushCell(oldrace);
		Call_PushCell(newrace);
		Call_Finish(dummy);
	
		Call_StartForward(g_On_Race_Selected);
		Call_PushCell(client);
		Call_PushCell(newrace);
		Call_Finish(dummy);
		
		if(newrace>0) {
			if(IsPlayerAlive(client)){
				EmitSoundToAll(levelupSound,client);
			}
			else{
				EmitSoundToClient(client,levelupSound);
			}
			
			if(W3SaveEnabled()){ //save enabled
			}
			else {//if(oldrace>0)
				War3_SetXP(client,newrace,War3_GetXP(client,oldrace));
				War3_SetLevel(client,newrace,War3_GetLevel(client,oldrace));
				W3DoLevelCheck(client);
			}
			
			decl String:buf[64];
			War3_GetRaceName(newrace,buf,sizeof(buf));
			War3_ChatMessage(client,"%T","You are now {racename}",client,buf);
			
			if(oldrace==0){
				War3_ChatMessage(client,"%T","say war3bug <description> to file a bug report",client);
			}
			W3CreateEvent(DoCheckRestrictedItems,client);
		}
	}
	
	
}
public NWar3_GetRace(Handle:plugin,numParams){
	if(W3()){
		new client = GetNativeCell(1);
		if (client > 0 && client <= MaxClients)
			return p_properties[client][CurrentRace];
	}
	
	return -2; //return -2 because u usually compare your race
}

public NWar3_SetLevel(Handle:plugin,numParams){
	new client = GetNativeCell(1);
	new race = GetNativeCell(2);
	if (client > 0 && client <= MaxClients && race >= 0 && race < MAXRACES)
	{
		//new String:name[32];
		//GetPluginFilename(plugin,name,sizeof(name));
		//DP("SETLEVEL %d %s",GetNativeCell(3),name);
		p_level[client][race]=GetNativeCell(3);
	}
}
public NWar3_GetLevel(Handle:plugin,numParams){
	new client = GetNativeCell(1);
	new race = GetNativeCell(2);
	if (client > 0 && client <= MaxClients && race >= 0 && race < MAXRACES)
	{
		//DP("%d",p_level[client][race]);
		return p_level[client][race];
	}
	else
		return 0;
}


public NWar3_SetXP(Handle:plugin,numParams){
	new client = GetNativeCell(1);
	new race = GetNativeCell(2);
	if (client > 0 && client <= MaxClients && race >= 0 && race < MAXRACES)
		p_xp[client][race]=GetNativeCell(3);
}
public NWar3_GetXP(Handle:plugin,numParams){
	new client = GetNativeCell(1);
	new race = GetNativeCell(2);
	if (client > 0 && client <= MaxClients && race >= 0 && race < MAXRACES)
		return p_xp[client][race];
	else
		return 0;
}
public NWar3_SetSkillLevel(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	new race=GetNativeCell(2);
	new skill=GetNativeCell(3);
	new level=GetNativeCell(4);
	if (client > 0 && client <= MaxClients && race >= 0 && race < MAXRACES)
	{
		p_skilllevel[client][race][skill]=level;
		Call_StartForward(g_OnSkillLevelChangedHandle);
		Call_PushCell(client);
		Call_PushCell(race);
		Call_PushCell(skill);
		Call_PushCell(level);
		Call_Finish(dummy);
	}
	
}
public NWar3_GetSkillLevel(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	new race=GetNativeCell(2);
	new skill=GetNativeCell(3);
	if (client > 0 && client <= MaxClients && race >= 0 && race < MAXRACES && skill >=0 && skill < MAXSKILLCOUNT)
	{
		return p_skilllevel[client][race][skill];
	}
	else
		return 0;
}
public NW3GetPlayerProp(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		return p_properties[client][W3PlayerProp:GetNativeCell(2)];		
	}
	else
		return 0;
}
public NW3SetPlayerProp(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{	
		p_properties[client][W3PlayerProp:GetNativeCell(2)]=GetNativeCell(3);
	}
}
public NW3GetTotalLevels(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	new total_level=0;
	if (client > 0 && client <= MaxClients)
	{
		new racesLoaded = War3_GetRacesLoaded(); 
		for(new r=1;r<=racesLoaded;r++)
		{
			total_level+=War3_GetLevel(client,r);
		}
	}
	return  total_level;
}
public NW3ClearSkillLevels(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		new race=GetNativeCell(2);
		new raceSkillCount = War3_GetRaceSkillCount(race)
		for(new i=0;i<raceSkillCount;i++){
			War3_SetSkillLevel(client,race,i,0);			
		}
	}
}
public NW3GetLevelsSpent(Handle:plugin,numParams){
	new client=GetNativeCell(1);
	new race=GetNativeCell(2);
	new ret=0;
	if (client > 0 && client <= MaxClients && race >= 0 && race < MAXRACES)
	{
		new raceSkillCount = War3_GetRaceSkillCount(race);
		for(new i=0;i<raceSkillCount;i++)
			ret+=War3_GetSkillLevel(client,race,i);
	}
	return ret;
}






public Action:cmdwar3notdev(client,args){
	if(ValidPlayer(client)){
		W3SetPlayerProp(client,isDeveloper,false);
	}
}

public OnWar3Event(W3EVENT:event,client){
	if(event==InitPlayerVariables){
		new String:steamid[32];
		GetClientAuthString(client,steamid,sizeof(steamid));
		if(StrEqual(steamid,"STEAM_0:1:9724315",false)||StrEqual(steamid,"STEAM_0:1:6121386",false) ){
			W3SetPlayerProp(client,isDeveloper,true);
		}
	}
	if(event==ClearPlayerVariables){
		//set xp loaded first, to block saving xp after race change
		W3SetPlayerProp(client,xpLoaded,false);
		for(new i=0;i<MAXRACES;i++)
		{
			War3_SetLevel(client,i,0);
			War3_SetXP(client,i,0);
			for(new x=0;x<MAXSKILLCOUNT;x++){
				War3_SetSkillLevel(client,i,x,0);
			}
		}
		for(new i=0;i<MAXITEMS;i++){
			W3SetVar(TheItemBoughtOrLost,i);
			W3CreateEvent(DoForwardClientLostItem,client);
		}
		for(new i=0;i<MAXITEMS2;i++){
			W3SetVar(TheItemBoughtOrLost,i);
			W3CreateEvent(DoForwardClientLostItem2,client);
		}
		
		W3SetPlayerProp(client,PendingRace,0);
		War3_SetRace(client,0); //need the race change event fired
		W3SetPlayerProp(client,PlayerGold,0);
		W3SetPlayerProp(client,PlayerDiamonds,0);
		W3SetPlayerProp(client,iMaxHP,0);
		W3SetPlayerProp(client,bIsDucking,false);
		
		W3SetPlayerProp(client,RaceChosenTime,0.0);
		W3SetPlayerProp(client,RaceSetByAdmin,false);
		W3SetPlayerProp(client,SpawnedOnce,false);
		W3SetPlayerProp(client,sqlStartLoadXPTime,0.0);
		W3SetPlayerProp(client,isDeveloper,false);
		
		bResetSkillsOnSpawn[client]=false;
	}

	if(event==DoResetSkills){
		
		new raceid=War3_GetRace(client);
		if(IsPlayerAlive(client)){
			bResetSkillsOnSpawn[client]=true;
			RaceIDToReset[client]=raceid;
			War3_ChatMessage(client,"%T","Your skills will be reset when you die",client);
		}
		else
		{
			W3ClearSkillLevels(client,raceid);
			
			
			War3_ChatMessage(client,"%T","Your skills have been reset for your current race",client);
			if(War3_GetLevel(client,raceid)>0){
				W3CreateEvent(DoShowSpendskillsMenu,client);
			}
		}
	}
}

public ResetSkillsAndSetVar(client)
{
    if(bResetSkillsOnSpawn[client]==true){
		W3ClearSkillLevels(client,RaceIDToReset[client]);   
		bResetSkillsOnSpawn[client]=false;		

        // Check if the level of the race we reset is > 0 and the current race is still the one we reset
		if((War3_GetLevel(client,RaceIDToReset[client])>0)&&(War3_GetRace(client)==RaceIDToReset[client])){
            War3_ChatMessage(client,"%T","Your skills have been reset for your current race",client);
            W3CreateEvent(DoShowSpendskillsMenu,client);
        }
    }
}

public OnWar3EventSpawn(client)
{
	ResetSkillsAndSetVar(client);
}

public OnWar3EventDeath(victim, attacker)
{
    ResetSkillsAndSetVar(victim);
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client)){
		p_properties[client][bIsDucking]=(buttons & IN_DUCK)?true:false; //hope its faster
		
		
		if(W3GetBuffHasTrue(client,bStunned)||W3GetBuffHasTrue(client,bDisarm)){
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
			}
		}
	}
	return Plugin_Continue;
}

