function(doc){
	if(doc.stime){
		var d = new Date();
		d.setTime(doc.stime * 1000); // stime is JST +0900 , millisec
		var key = [d.getFullYear(),(d.getMonth()+1),d.getDate()];
		
 		var value = {"count":1,
			"max":doc.solarpower,
			"min":doc.solarpower,
			"ave":doc.solarpower};
		
		emit(key, value);
	}
}