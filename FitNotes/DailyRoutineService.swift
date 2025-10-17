import Foundation
import SwiftData

public final class DailyRoutineService {
    public static let shared = DailyRoutineService()
    private init() {}
    
    public func createDailyRoutine(
        name: String,
        date: Date = Date(),
        notes: String? = nil,
        modelContext: ModelContext
    ) -> DailyRoutine {
        let routine = DailyRoutine(
            name: name,
            date: date,
            notes: notes
        )
        modelContext.insert(routine)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving daily routine: \(error)")
        }
        
        return routine
    }
    
    public func addExerciseToRoutine(
        routine: DailyRoutine,
        exerciseId: UUID,
        sets: Int = 1,
        reps: Int? = nil,
        weight: Double? = nil,
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        modelContext: ModelContext
    ) -> RoutineExercise {
        let order = routine.exercises.count + 1
        
        let routineExercise = RoutineExercise(
            exerciseId: exerciseId,
            order: order,
            sets: sets,
            reps: reps,
            weight: weight,
            duration: duration,
            distance: distance,
            notes: notes
        )
        
        routineExercise.dailyRoutine = routine
        modelContext.insert(routineExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving routine exercise: \(error)")
        }
        
        return routineExercise
    }
    
    public func removeExerciseFromRoutine(
        routineExercise: RoutineExercise,
        modelContext: ModelContext
    ) {
        modelContext.delete(routineExercise)
        
        // Reorder remaining exercises
        if let routine = routineExercise.dailyRoutine {
            let remainingExercises = routine.exercises
                .filter { $0.id != routineExercise.id }
                .sorted { $0.order < $1.order }
            
            for (index, exercise) in remainingExercises.enumerated() {
                exercise.order = index + 1
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error removing routine exercise: \(error)")
        }
    }
    
    public func reorderExercises(
        routine: DailyRoutine,
        from: IndexSet,
        to: Int,
        modelContext: ModelContext
    ) {
        routine.exercises.move(fromOffsets: from, toOffset: to)
        
        // Update order values
        for (index, exercise) in routine.exercises.enumerated() {
            exercise.order = index + 1
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error reordering exercises: \(error)")
        }
    }
    
    public func getTodaysRoutine(modelContext: ModelContext) -> DailyRoutine? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate { routine in
                routine.date >= today && routine.date < tomorrow
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let routines = try modelContext.fetch(descriptor)
            return routines.first
        } catch {
            print("Error fetching today's routine: \(error)")
            return nil
        }
    }
    
    public func getRoutinesForWeek(modelContext: ModelContext) -> [DailyRoutine] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? today
        
        let descriptor = FetchDescriptor<DailyRoutine>(
            predicate: #Predicate { routine in
                routine.date >= weekStart && routine.date < weekEnd
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching week's routines: \(error)")
            return []
        }
    }
    
    public func completeRoutine(_ routine: DailyRoutine, modelContext: ModelContext) {
        routine.isCompleted = true
        routine.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error completing routine: \(error)")
        }
    }
}

// MARK: - RoutineService (Template Management)
public final class RoutineService {
    public static let shared = RoutineService()
    private init() {}
    
    // MARK: - Routine Template Management
    
    public func createRoutine(
        name: String,
        description: String? = nil,
        modelContext: ModelContext
    ) -> Routine {
        let routine = Routine(
            name: name,
            routineDescription: description
        )
        modelContext.insert(routine)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving routine: \(error)")
        }
        
        return routine
    }
    
    public func addExerciseToRoutine(
        routine: Routine,
        exerciseId: UUID,
        sets: Int = 1,
        reps: Int? = nil,
        weight: Double? = nil,
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        modelContext: ModelContext
    ) -> RoutineExercise {
        let order = routine.exercises.count + 1
        
        let routineExercise = RoutineExercise(
            exerciseId: exerciseId,
            order: order,
            sets: sets,
            reps: reps,
            weight: weight,
            duration: duration,
            distance: distance,
            notes: notes
        )
        
        routineExercise.routine = routine
        modelContext.insert(routineExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving routine exercise: \(error)")
        }
        
        return routineExercise
    }
    
    public func removeExerciseFromRoutine(
        routineExercise: RoutineExercise,
        modelContext: ModelContext
    ) {
        modelContext.delete(routineExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Error removing routine exercise: \(error)")
        }
    }
    
    public func deleteRoutine(
        routine: Routine,
        modelContext: ModelContext
    ) {
        modelContext.delete(routine)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting routine: \(error)")
        }
    }
    
    // MARK: - Create DailyRoutine from Routine Template
    
    public func createDailyRoutineFromTemplate(
        routine: Routine,
        date: Date = Date(),
        notes: String? = nil,
        modelContext: ModelContext
    ) -> DailyRoutine {
        let dailyRoutine = DailyRoutine(
            name: routine.name,
            date: date,
            notes: notes,
            routineTemplateId: routine.id
        )
        modelContext.insert(dailyRoutine)
        
        // Copy exercises from template
        for templateExercise in routine.exercises.sorted(by: { $0.order < $1.order }) {
            let dailyExercise = RoutineExercise(
                exerciseId: templateExercise.exerciseId,
                order: templateExercise.order,
                sets: templateExercise.sets,
                reps: templateExercise.reps,
                weight: templateExercise.weight,
                duration: templateExercise.duration,
                distance: templateExercise.distance,
                notes: templateExercise.notes
            )
            dailyExercise.dailyRoutine = dailyRoutine
            modelContext.insert(dailyExercise)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error creating daily routine from template: \(error)")
        }
        
        return dailyRoutine
    }
}
