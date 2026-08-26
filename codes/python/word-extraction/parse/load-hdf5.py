import h5py
import numpy as np
from datetime import datetime
from docx import Document
import re

class WordToHDF5:
    def __init__(self, hdf5_filename):
        """Initialize HDF5 file handler"""
        self.hdf5_filename = hdf5_filename
    
    def parse_word_document(self, word_filename):
        """
        Parse Word document with structure:
        - Date: 3/19/2026
        - account: string
        - element: string
        - gov: list of strings
        - ctr: list of strings
        - leadership: long string
        - leadership confidence: integer (0-100 or 1-10)
        - leadership rational: long string
        """
        doc = Document(word_filename)
        
        # Extract all paragraphs
        paragraphs = [p.text.strip() for p in doc.paragraphs if p.text.strip()]
        
        records = []
        current_record = {}
        
        i = 0
        while i < len(paragraphs):
            line = paragraphs[i]
            
            # Detect date pattern (MM/DD/YYYY)
            date_match = re.match(r'(\d{1,2}/\d{1,2}/\d{4})', line)
            if date_match:
                # If we have a previous record, save it
                if current_record:
                    records.append(current_record)
                    current_record = {}
                
                # Start new record
                current_record['date'] = datetime.strptime(date_match.group(1), '%m/%d/%Y')
                i += 1
                continue
            
            # Parse key-value pairs
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip().lower()
                value = value.strip()
                
                if key == 'account':
                    current_record['account'] = value
                
                elif key == 'element':
                    current_record['element'] = value
                
                elif key == 'gov':
                    # Could be a single value or comma-separated list
                    current_record['gov'] = [v.strip() for v in value.split(',') if v.strip()]
                
                elif key == 'ctr':
                    current_record['ctr'] = [v.strip() for v in value.split(',') if v.strip()]
                
                elif key == 'leadership':
                    current_record['leadership'] = value
                
                elif key == 'leadership confidence' or key == 'confidence':
                    # Convert to integer
                    try:
                        current_record['confidence'] = int(value)
                    except ValueError:
                        # If it's a percentage like "85%"
                        if '%' in value:
                            current_record['confidence'] = int(value.replace('%', '').strip())
                        else:
                            current_record['confidence'] = 0
                
                elif key == 'leadership rational' or key == 'rational':
                    current_record['rational'] = value
            
            i += 1
        
        # Don't forget the last record
        if current_record:
            records.append(current_record)
        
        return records
    
    def save_to_hdf5(self, records, dataset_name='word_data'):
        """Save parsed records to HDF5 file"""
        if not records:
            print("No data to save")
            return
        
        with h5py.File(self.hdf5_filename, 'w') as f:
            # Create main group
            grp = f.create_group(dataset_name)
            
            # Prepare data for storage
            dates = [r['date'].isoformat() for r in records]
            accounts = [r.get('account', '') for r in records]
            elements = [r.get('element', '') for r in records]
            gov_lists = [', '.join(r.get('gov', [])) for r in records]
            ctr_lists = [', '.join(r.get('ctr', [])) for r in records]
            leaderships = [r.get('leadership', '') for r in records]
            confidences = [r.get('confidence', 0) for r in records]
            rationals = [r.get('rational', '') for r in records]
            
            # Create datasets with variable-length strings
            dt = h5py.special_dtype(vlen=str)
            
            grp.create_dataset('dates', data=np.array(dates, dtype=dt))
            grp.create_dataset('accounts', data=np.array(accounts, dtype=dt))
            grp.create_dataset('elements', data=np.array(elements, dtype=dt))
            grp.create_dataset('gov', data=np.array(gov_lists, dtype=dt))
            grp.create_dataset('ctr', data=np.array(ctr_lists, dtype=dt))
            grp.create_dataset('leadership', data=np.array(leaderships, dtype=dt))
            grp.create_dataset('confidence', data=np.array(confidences, dtype=np.int16))
            grp.create_dataset('rational', data=np.array(rationals, dtype=dt))
            
            # Store as structured array (alternative approach)
            structured_dtype = np.dtype([
                ('date', 'S20'),
                ('account', 'S200'),
                ('element', 'S200'),
                ('gov', 'S500'),
                ('ctr', 'S500'),
                ('leadership', 'S1000'),
                ('confidence', np.int16),
                ('rational', 'S2000')
            ])
            
            structured_data = np.array([
                (
                    r['date'].isoformat().encode(),
                    r.get('account', '').encode(),
                    r.get('element', '').encode(),
                    ', '.join(r.get('gov', [])).encode(),
                    ', '.join(r.get('ctr', [])).encode(),
                    r.get('leadership', '').encode(),
                    r.get('confidence', 0),
                    r.get('rational', '').encode()
                ) for r in records
            ], dtype=structured_dtype)
            
            grp.create_dataset('structured_data', data=structured_data)
            
            # Add metadata
            grp.attrs['created_date'] = datetime.now().isoformat()
            grp.attrs['record_count'] = len(records)
            grp.attrs['fields'] = ['date', 'account', 'element', 'gov', 'ctr', 
                                   'leadership', 'confidence', 'rational']
        
        print(f"Saved {len(records)} records to {self.hdf5_filename}")
    
    def read_from_hdf5(self, dataset_name='word_data'):
        """Read data back from HDF5 file"""
        with h5py.File(self.hdf5_filename, 'r') as f:
            grp = f[dataset_name]
            
            # Read from structured data
            structured_data = grp['structured_data'][:]
            
            records = []
            for item in structured_data:
                record = {
                    'date': datetime.fromisoformat(item['date'].decode()),
                    'account': item['account'].decode(),
                    'element': item['element'].decode(),
                    'gov': [g.strip() for g in item['gov'].decode().split(',') if g.strip()],
                    'ctr': [c.strip() for c in item['ctr'].decode().split(',') if c.strip()],
                    'leadership': item['leadership'].decode(),
                    'confidence': int(item['confidence']),
                    'rational': item['rational'].decode()
                }
                records.append(record)
            
            return records
    
    def query_by_date(self, start_date=None, end_date=None, dataset_name='word_data'):
        """Query records by date range"""
        records = self.read_from_hdf5(dataset_name)
        
        if start_date:
            records = [r for r in records if r['date'] >= start_date]
        if end_date:
            records = [r for r in records if r['date'] <= end_date]
        
        return records
    
    def query_by_confidence(self, min_confidence=None, max_confidence=None, dataset_name='word_data'):
        """Query records by confidence score"""
        records = self.read_from_hdf5(dataset_name)
        
        if min_confidence is not None:
            records = [r for r in records if r['confidence'] >= min_confidence]
        if max_confidence is not None:
            records = [r for r in records if r['confidence'] <= max_confidence]
        
        return records
    
    def query_by_account(self, account, dataset_name='word_data'):
        """Query records by account name"""
        records = self.read_from_hdf5(dataset_name)
        return [r for r in records if r['account'].lower() == account.lower()]

# Alternative: Using pandas for easier analysis
import pandas as pd

class WordToHDF5Pandas:
    def __init__(self, hdf5_filename):
        self.hdf5_filename = hdf5_filename
    
    def parse_to_dataframe(self, word_filename):
        """Parse Word document and return pandas DataFrame"""
        processor = WordToHDF5('temp.h5')
        records = processor.parse_word_document(word_filename)
        
        # Convert to DataFrame
        df = pd.DataFrame(records)
        
        # Convert gov and ctr lists to strings for storage
        df['gov_str'] = df['gov'].apply(lambda x: ', '.join(x) if isinstance(x, list) else '')
        df['ctr_str'] = df['ctr'].apply(lambda x: ', '.join(x) if isinstance(x, list) else '')
        
        return df
    
    def save_to_hdf5(self, df, key='word_data'):
        """Save DataFrame to HDF5"""
        df.to_hdf(self.hdf5_filename, key=key, mode='w', format='table')
        print(f"Saved {len(df)} records to {self.hdf5_filename}")
    
    def read_from_hdf5(self, key='word_data'):
        """Read DataFrame from HDF5"""
        return pd.read_hdf(self.hdf5_filename, key=key)
    
    def query(self, key='word_data', account=None, min_confidence=None, 
              date_start=None, date_end=None):
        """Query the data with multiple filters"""
        df = self.read_from_hdf5(key)
        
        if account:
            df = df[df['account'].str.lower() == account.lower()]
        
        if min_confidence:
            df = df[df['confidence'] >= min_confidence]
        
        if date_start:
            df = df[df['date'] >= date_start]
        
        if date_end:
            df = df[df['date'] <= date_end]
        
        return df

# Usage example
if __name__ == "__main__":
    # Using the pure HDF5 approach
    processor = WordToHDF5('word_data.h5')
    
    # Parse Word document
    records = processor.parse_word_document('sample.docx')
    
    # Print first record for verification
    if records:
        print("First record:")
        for key, value in records[0].items():
            print(f"  {key}: {value}")
    
    # Save to HDF5
    processor.save_to_hdf5(records)
    
    # Read back
    retrieved = processor.read_from_hdf5()
    print(f"\nRetrieved {len(retrieved)} records")
    
    # Query examples
    from datetime import datetime
    recent = processor.query_by_date(
        start_date=datetime(2026, 1, 1),
        end_date=datetime(2026, 12, 31)
    )
    print(f"Found {len(recent)} records in 2026")
    
    high_confidence = processor.query_by_confidence(min_confidence=80)
    print(f"Found {len(high_confidence)} records with confidence >= 80")
    
    # Using pandas approach
    pandas_processor = WordToHDF5Pandas('word_data_pandas.h5')
    df = pandas_processor.parse_to_dataframe('sample.docx')
    pandas_processor.save_to_hdf5(df)
    
    # Query with pandas
    results = pandas_processor.query(
        account='SomeAccount',
        min_confidence=75,
        date_start=datetime(2026, 1, 1)
    )
    print(f"\nPandas query found {len(results)} records")
    print(results[['date', 'account', 'confidence', 'leadership']].head())