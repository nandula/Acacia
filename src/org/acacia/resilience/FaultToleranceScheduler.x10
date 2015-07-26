/**
Copyright 2015 Acacia Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

package org.acacia.resilience;

import x10.compiler.Native;
import x10.util.ArrayList;
import x10.util.HashMap;
import x10.util.Set;
import x10.util.HashSet;
import x10.util.StringBuilder;

import x10.regionarray.Array;
import x10.util.Map.Entry;

import org.acacia.util.Utils;
import org.acacia.util.Conts;
import org.acacia.util.PlaceToNodeMapper;

import org.acacia.server.AcaciaServer;

public class FaultToleranceScheduler {
	/**
	 * Default constructor 
	 */
	public def this() {
	}

	/**
	 * This method partitions the graph with replications.
	 */
	public static def mapReplicationstoPlaces(): HashMap[Int, String]{
		//val converter:MetisPartitioner = new MetisPartitioner();	
		var resilienceLevel:Int = Int.parse(Utils.call_getAcaciaProperty("org.acacia.resilience.resilienceLevel"));

		if(resilienceLevel != 0n) {
			val nPlaces:Int = Place.places().size() as Int;
			val itr:Iterator[Place] = Place.places().iterator();
			val placeToHostMap:HashMap[Long, String] = new HashMap[Long, String]();

			//We don't need hostPlaceCounter, it can be generated by using the Arraylist length in hostToPlaceMap. But used it for temporary manner.
			val hostPlaceCounter:HashMap[String, Int] = new HashMap[String, int]();

			//counterForHoasts is for used in the case where nHosts>1
			val counterForHoasts:HashMap[String, Int] = new HashMap[String, int]();
			val counterForPlacesByHost:HashMap[String, HashMap[Int,Int]] = new HashMap[String, HashMap[Int,Int]]();

			//hostToPlaceMap maps list of places to the corresponding host 
			val hostToPlaceMap:HashMap[String, ArrayList[Int]] = new HashMap[String, ArrayList[Int]]();

			val result:HashMap[Int, String] = new HashMap[Int, String]();
		
			//The three methods to get the nHost - HostLists
			val hostLst:Rail[String] = org.acacia.util.Utils.getPrivateHostList();
			val hostIDMap:HashMap[String, String] = AcaciaServer.getLiveHostIDList();
			//var hostList:HashSet[String] = new HashSet[String]();			
		
			while(itr.hasNext()){
				val p:Place = itr.next();
				Console.OUT.println("resilience p.id " + p.id);
			
				val hostName:String = PlaceToNodeMapper.getHost(p.id);	
				if(hostPlaceCounter.containsKey(hostName))
				{
					var PlaceConterMap:HashMap[Int,Int] = counterForPlacesByHost.get(hostName);
					PlaceConterMap.put(p.id as Int,0n);
					counterForPlacesByHost.put(hostName,PlaceConterMap);
					hostPlaceCounter.put(hostName,hostPlaceCounter.get(hostName) + 1n);
					var temp:ArrayList[Int] = hostToPlaceMap.get(hostName);
					temp.add(p.id as Int);
					hostToPlaceMap.put(hostName, temp);
				}
				else
				{
					hostPlaceCounter.put(hostName,1n);
					counterForHoasts.put(hostName,0n);
					var PlaceConterMap:HashMap[Int,Int] = new HashMap[Int,Int]();
					//usedHostsCounter is the counter of hosts that exceeded the reference number.
					PlaceConterMap.put(-1n,0n);
					//ReferenceForHosts is the reference number for the counter values. 
					PlaceConterMap.put(-2n,0n);
					//nextLevel is a counter of Hosts that exceeded the reference number+1. Only used in one case
					PlaceConterMap.put(-3n,0n);

					PlaceConterMap.put(p.id as Int,0n);
					counterForPlacesByHost.put(hostName,PlaceConterMap);
					var temp:ArrayList[Int] = new ArrayList[Int]();
					temp.add(p.id as Int);
					hostToPlaceMap.put(hostName, temp);
				}
				//hostList.add(hostName);
				Console.OUT.println("resilience p.id " + p.id + " hostName : " + hostName);
		
				placeToHostMap.put(p.id, hostName);
				Console.OUT.println("placeToHostMap entry for place" + p.id);
			}
			Console.OUT.println("placeToHostMap Created");
		
			//The three methods to get the nHost - nHost
			val hostLstLen:Int = hostLst.size as Int;
			val hostIDMapLen:Int = hostIDMap.size() as Int;
			val hostListLen:Int = hostPlaceCounter.size() as Int;
			val nHosts:Int = hostLstLen;
		
			Console.OUT.println("placeToHostMap.entries() : " + placeToHostMap.entries().size());
			var itr2:Iterator[x10.util.Map.Entry[Long, String]] = placeToHostMap.entries().iterator();

			if(resilienceLevel >= nPlaces - 1n){
				while(itr2.hasNext()){
					var frequency:Int=nPlaces;
					val itemPlace:x10.util.Map.Entry[Long, String] = itr2.next();
					val pid:Int=itemPlace.getKey() as int;
					var resultString:String = "";
					if(itemPlace==null){
						break;
					}
					for (var k:Int = 0n; k < nPlaces; k++){
						resultString = resultString + k;
						if(k<nPlaces-1)
						{
							resultString = resultString + ",";
						}									
					}
					resultString = resultString + "$";
					result.put(pid,resultString);
					Console.OUT.println("Replications in all the places");
				}
				return result;
			}
	
			if(nHosts==1n) {
				val counter = new Rail[Int](nPlaces+1);
				//i is the reference number for the counter values. 
				//counter(nPlaces) is the counter of places that exceeded the reference number.
				var i:Int=0n;
				//nextLevel is a counter of places that exceeded the reference number+1. Only used in one case
				var nextLevel:Int=0n;
				while(itr2.hasNext()){
					val itemPlace:x10.util.Map.Entry[Long, String] = itr2.next();
					val pid:Int=itemPlace.getKey() as int;
					var resultString:String = "";
					if(itemPlace==null){
						break;
					}
					for (var k:Int = 0n; k < resilienceLevel; k++){
						var completed:Boolean = false;
						for (var j:Int = 0n; j < nPlaces; j++){
							if(pid != j){
								if(counter(j) == i) {

									counter(j)++;
									resultString = resultString + j;
									counter(nPlaces)++;
									completed = true;
									if(counter(nPlaces) == nPlaces){
										counter(nPlaces) = nextLevel;
										i++;
										nextLevel = 0n;
									}
									break;
								}
							}
						}
						if(completed == false){
							for (var j:Int = 0n; j < nPlaces; j++){
								if(pid != j){
									if(counter(j) == i+1n) {
										counter(j)++;
										resultString = resultString + j;
										nextLevel++;
										completed = true;
										break;
									}
								}
							}
						}
						if(k<resilienceLevel-1n)
						{
						resultString = resultString + ",";
						}
					}
					resultString = resultString + "$";
					result.put(pid,resultString);
					Console.OUT.println("Only One Host - Replications " + i+1 + " in" + counter(nPlaces)+ "places. Replications "+i+2+ "in "+nextLevel+" places. All other have "+i+"Replications.");
				}
				return result;
			}
			if(nHosts>1) {
				//if(nHosts <= resilienceLevel)
				//{
					//counterForHoasts created in the begining will be used as the counter
					//usedHostsCounter is the counter of hosts that exceeded the reference number.
					var usedHostsCounter:Int=0n;
					//ReferenceForHosts is the reference number for the counter values. 					
					var referenceForHosts:Int=0n;
					//nextLevel is a counter of Hosts that exceeded the reference number+1. Only used in one case
					var nextLevelForHosts:Int=0n;
					while(itr2.hasNext()){
						val itemPlace:x10.util.Map.Entry[Long, String] = itr2.next();
						val pid:Int=itemPlace.getKey() as int;
						var resultString:String = "";
						if(itemPlace==null){
							break;
						}
						val hostName:String = itemPlace.getValue();
						//var hostItr:Iterator[x10.util.Map.Entry[String, HashMap[Int,Int]]] = counterForPlacesByHost.entries().iterator();
						var hostItr:Iterator[x10.util.Map.Entry[String, ArrayList[Int]]] = hostToPlaceMap.entries().iterator();
						while(hostItr.hasNext())
						{
							val itemHost:x10.util.Map.Entry[String, ArrayList[Int]] = hostItr.next();
							val hostID:String = itemHost.getKey();
							var placeList:ArrayList[Int] = itemHost.getValue();
							// val itemHost:x10.util.Map.Entry[String, HashMap[Int,Int]] = hostItr.next();
							// val hostID:String = itemHost.getKey();
							// var counterListByPlaces:HashMap[Int,Int] = itemHost.getValue();
							var counterListByPlaces:HashMap[Int,Int] = counterForPlacesByHost.get(hostID);
							var i:Int = counterListByPlaces.get(-2n);
							var completed:Boolean = false;
							var placeItr:Iterator[Int] = placeList.iterator();
							while(placeItr.hasNext()){
								var j:Int = placeItr.next();
								if(pid != j){
									if(counterListByPlaces.get(j) == i) {
		
										counterListByPlaces.put(j,counterListByPlaces.get(j)+1n);
										resultString = resultString + j;
										counterListByPlaces.put(-1n,counterListByPlaces.get(-1n)+1n);
										completed = true;
										if(counterListByPlaces.get(-1n) == placeList.size() as Int){
											counterListByPlaces.put(-1n,counterListByPlaces.get(-3n));
											i++;
											counterListByPlaces.put(-2n,i);
											counterListByPlaces.put(-3n,0n);
										}
										break;
									}
								}
							}
							if(completed == false){
								var placeItr2:Iterator[Int] = placeList.iterator();
								while(placeItr2.hasNext()){
									var j:Int = placeItr2.next();
									if(pid != j){
										if(counterListByPlaces.get(j) == i+1n) {
										
											counterListByPlaces.put(j,counterListByPlaces.get(j)+1n);
											resultString = resultString + j;
											counterListByPlaces.put(-3n,counterListByPlaces.get(-3n)+1n);
											completed = true;											
											break;
										}
									}
								}								
							}
							if(hostItr.hasNext())
							{
								resultString = resultString + ",";
							}

						}
						resultString = resultString + "$";
						result.put(pid,resultString);
						//Console.OUT.println("More than One Host - Replications " + i+1 + " in" + counter(nPlaces)+ "places. Replications "+i+2+ "in "+nextLevel+" places. All other have "+i+"Replications.");

					}
				//}
				// if(nHosts > resilienceLevel)
				// {
				// 
				// }
				// if(nHosts < resilienceLevel)
				// {
				// //Will be implemented in future. For now use one replication for a host.
				// }
				
			}
			
			return result;
		}
		return null;
	}
		
}