/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "WCX - Dodge Engine",
	author = "necavi",
	description = "WCX - Dodge Engine",
	version = "0.1",
	url = "http://necavi.com"
}

public OnPluginStart()
{
	// Add your own code here...
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	new Float:EvadeChance = 0.0;
	EvadeChance += W3GetBuffStackedFloat(victim,fDodgeChance);
	War3_ChatMessage(victim,"%f",EvadeChance);
	if(EvadeChance>0.0)
	{
		if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
		{
			new vteam=GetClientTeam(victim);
			new ateam=GetClientTeam(attacker);
			if(vteam!=ateam)
			{
				new Float:Rand = GetRandomFloat(0.0,1.0);
				War3_ChatMessage(victim,"%f",Rand);
				if(!Hexed(victim,false) && Rand<=EvadeChance && !W3HasImmunity(attacker,Immunity_Skills))
				{
					War3_ChatMessage(victim,"We're there!");
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
					
					War3_DamageModPercent(0.0);
					
					W3MsgEvaded(victim,attacker);
					if(War3_GetGame()==Game_TF)
					{
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
					}
				}
			}
		}
	}
}



