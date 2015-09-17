package com.iflytek.msc 
{
	import flash.utils.ByteArray;
	
	public class CGrammar
	{
		private var m_grammar:ByteArray;
		private var m_type:String;
		private var m_weight:int;

		public function CGrammar( grammar:ByteArray, type:String, weight:int ) 
		{
			m_grammar = grammar;
			m_type = type;
			m_weight = weight;
		}
		
		public function setGrammar( grammar:ByteArray ):void
		{
			m_grammar = grammar;
		}
		
		public function getGrammar():ByteArray
		{
			return m_grammar;
		}
		
		public function setType( type:String ):void
		{
			m_type = type;
		}
		
		public function getType():String
		{
			return m_type;
		}
		
		public function setWeight( weight:int ):void
		{
			m_weight = weight;
		}
		
		public function getWeight():int
		{
			return m_weight;
		}

	}
	
}
