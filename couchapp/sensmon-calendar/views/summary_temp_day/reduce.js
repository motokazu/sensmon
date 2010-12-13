function(keys, values){
	var ave = 0;
	var	max = 0;
	var min = 100;
	var count = 0;
	
	values.forEach(function(val){
		max = Math.max(max,val.max);
		min = Math.min(min,val.min);
		ave += val.ave;
		count += val.count;
	});
	ave = ave/values.length;
	
	return {"count":count,"max":max,"min":min,"ave":ave};
}